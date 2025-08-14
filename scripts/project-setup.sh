#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.
set -o pipefail # Exit immediately if a command in a pipeline fails.

# --- Pre-flight check: Install gcloud beta components ---
echo "--- Ensuring gcloud beta components are installed ---"
gcloud components install beta --quiet
echo "Beta components are installed."

# --- Configuration ---
# GCP_PROJECT_ID should be set as an environment variable
# Example: export GCP_PROJECT_ID="your-gcp-project-id"
if [[ -z "$GCP_PROJECT_ID" ]]; then
    echo "Error: GCP_PROJECT_ID environment variable is not set."
    echo "Please set it before running this script: export GCP_PROJECT_ID=\"your-gcp-project-id\""
    exit 1
fi

export GCP_REGION=${GCP_REGION:-"EU"}
SERVICE_ACCOUNT_NAME="dbt-materializations-ci"
SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com"
KEY_FILE="local-gcloud-creds.json"
CUSTOM_JS_LIB_NAME="test_lib.js"
GCP_TEST_BUCKET_NAME="${GCP_PROJECT_ID}-bq-mat-tests"

echo "--- Using Configuration ---"
echo "Project ID:           ${GCP_PROJECT_ID}"
echo "Region:               ${GCP_REGION}"
echo "Service Account:      ${SERVICE_ACCOUNT_EMAIL}"
echo "Key File:             ${KEY_FILE}"
echo "---------------------------"

# --- Service Account and Key File ---
if [ ! -f "$KEY_FILE" ]; then
    echo "Key file '$KEY_FILE' not found. Setting up service account and creating a new key..."

    # Check if service account exists, create if not
    if ! gcloud iam service-accounts describe "$SERVICE_ACCOUNT_EMAIL" --project="$GCP_PROJECT_ID" > /dev/null 2>&1; then
        echo "Service account not found. Creating..."
        gcloud iam service-accounts create "$SERVICE_ACCOUNT_NAME" \
            --project="$GCP_PROJECT_ID" \
            --description="Service account for dbt-bigquery-materializations CI" \
            --display-name="DBT Materializations CI"
    else
        echo "Service account already exists."
    fi

    # Grant BigQuery Admin role
    echo "Ensuring BigQuery Admin role..."
    gcloud projects add-iam-policy-binding "$GCP_PROJECT_ID" \
        --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
        --role="roles/bigquery.admin" \
        --condition=None > /dev/null # Suppress verbose output

    # Grant Storage Admin role
    echo "Ensuring Storage Admin role..."
    gcloud projects add-iam-policy-binding "$GCP_PROJECT_ID" \
        --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
        --role="roles/storage.admin" \
        --condition=None > /dev/null # Suppress verbose output

    # Grant Data Catalog Admin role for creating policy tags
    echo "Ensuring Data Catalog Admin role..."
    gcloud projects add-iam-policy-binding "$GCP_PROJECT_ID" \
        --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
        --role="roles/datacatalog.admin" \
        --condition=None > /dev/null # Suppress verbose output

    # Grant Service Account User role to allow the service account to act as itself
    echo "Ensuring Service Account User role..."
    gcloud iam service-accounts add-iam-policy-binding "$SERVICE_ACCOUNT_EMAIL" \
        --project="$GCP_PROJECT_ID" \
        --role="roles/iam.serviceAccountUser" \
        --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" > /dev/null # Suppress verbose output


    # Create the key file
    echo "Creating new key file: $KEY_FILE"
    gcloud iam service-accounts keys create "$KEY_FILE" \
        --iam-account="$SERVICE_ACCOUNT_EMAIL" \
        --project="$GCP_PROJECT_ID"
else
    echo "Key file '$KEY_FILE' already exists. Skipping service account setup."
fi

# Always ensure the dbt service account can read Data Catalog taxonomies in this project
echo "Ensuring Data Catalog Viewer role for dbt service account on project ${GCP_PROJECT_ID}..."
gcloud projects add-iam-policy-binding "$GCP_PROJECT_ID" \
    --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
    --role="roles/datacatalog.viewer" \
    --condition=None > /dev/null # Suppress verbose output

# --- Create BigQuery Connection and Grant Permissions ---
# This must be done BEFORE activating the service account, as it requires project-level permissions
# to grant IAM roles.
echo ""
echo "--- Creating BigQuery Connection ---"
CONNECTION_ID="dbt-bigquery-materializations-con"
# Check if the connection already exists.
if ! bq show --connection --project_id="$GCP_PROJECT_ID" --location="$GCP_REGION" "$CONNECTION_ID" &> /dev/null; then
    echo "Creating BigQuery Connection: $CONNECTION_ID"
    bq mk --connection --location="$GCP_REGION" --project_id="$GCP_PROJECT_ID" \
        --connection_type=CLOUD_RESOURCE "$CONNECTION_ID"
else
    echo "BigQuery Connection '$CONNECTION_ID' already exists."
fi

# Get the connection's service account
echo "Retrieving connection's service account..."
CONNECTION_SA=$(bq show --connection --format=prettyjson "${GCP_PROJECT_ID}.${GCP_REGION}.${CONNECTION_ID}" | grep "serviceAccountId" | awk -F '"' '{print $4}')

if [[ -z "$CONNECTION_SA" ]]; then
    echo "Error: Could not retrieve service account for connection '$CONNECTION_ID'."
    exit 1
fi
echo "Connection Service Account: ${CONNECTION_SA}"

# Grant Data Catalog Viewer role to the connection's service account so it can read taxonomies referenced by policy tags
echo "Granting Data Catalog Viewer role to the connection's service account on the project..."
gcloud projects add-iam-policy-binding "$GCP_PROJECT_ID" \
    --member="serviceAccount:$CONNECTION_SA" \
    --role="roles/datacatalog.viewer" \
    --condition=None > /dev/null # Suppress verbose output

# Grant Storage Object Viewer role to the connection's service account to allow it to read from GCS
echo "Granting Storage Object Viewer role to the connection's service account on the specific GCS bucket..."
gcloud storage buckets add-iam-policy-binding "gs://${GCP_TEST_BUCKET_NAME}" \
    --member="serviceAccount:$CONNECTION_SA" \
    --role="roles/storage.objectViewer"

DBT_BIGQUERY_CONNECTION="projects/${GCP_PROJECT_ID}/locations/${GCP_REGION}/connections/${CONNECTION_ID}"

# --- GCS Bucket and Test Files ---
echo ""
echo "--- Setting up GCS Bucket and Test Files ---"
echo "Bucket Name:          ${GCP_TEST_BUCKET_NAME}"

# Create the GCS bucket if it doesn't exist
if ! gcloud storage buckets describe "gs://${GCP_TEST_BUCKET_NAME}" > /dev/null 2>&1; then
    echo "Creating GCS bucket: gs://${GCP_TEST_BUCKET_NAME}"
    gcloud storage buckets create "gs://${GCP_TEST_BUCKET_NAME}" --project="$GCP_PROJECT_ID" --location="$GCP_REGION"
else
    echo "GCS bucket gs://${GCP_TEST_BUCKET_NAME} already exists."
fi

# --- Create and Upload Custom JS Library ---
echo "Creating custom JS library: ${CUSTOM_JS_LIB_NAME}"
cat <<EOF > "$CUSTOM_JS_LIB_NAME"
function getConstant() {
  return 'TestCorp';
}
EOF

# Upload the custom library to the bucket
echo "Uploading ${CUSTOM_JS_LIB_NAME} to GCS..."
gcloud storage cp "$CUSTOM_JS_LIB_NAME" "gs://${GCP_TEST_BUCKET_NAME}/${CUSTOM_JS_LIB_NAME}"

# Remove the local temp file
rm "$CUSTOM_JS_LIB_NAME"

# Upload the seed file to GCS
echo "Uploading seed file to GCS..."
gcloud storage cp "integration_tests/seeds/example_external_table_data.csv" "gs://${GCP_TEST_BUCKET_NAME}/example_external_table_data.csv"

# Create or use an existing policy tag for testing
if [[ -n "$DBT_POLICY_TAG" ]]; then
  echo "Using existing DBT_POLICY_TAG from environment: ${DBT_POLICY_TAG}"
else
  echo "Creating policy tag taxonomy and policy tag..."
  DBT_POLICY_TAG=$(python scripts/create_policy_tag.py | tail -n 1)
fi

# Validate that we received a valid-looking policy tag resource name
if ! [[ "$DBT_POLICY_TAG" =~ ^projects/.*/locations/.*/taxonomies/.*/policyTags/.*$ ]]; then
    echo "Error: Failed to create or retrieve a valid policy tag resource name."
    echo "The script returned: '$DBT_POLICY_TAG'"
    echo "Please check the output above for any error messages from the script."
    exit 1
fi
echo "Policy Tag created successfully: ${DBT_POLICY_TAG}"

# Ensure dbt service account has Data Catalog Viewer on the taxonomy project (handles cross-project taxonomies)
# Extract the project after 'projects/' (field 2)
PT_PROJECT=$(echo "$DBT_POLICY_TAG" | cut -d'/' -f2)
if [[ "$PT_PROJECT" != "$GCP_PROJECT_ID" ]]; then
    echo "Granting Data Catalog Viewer role to ${SERVICE_ACCOUNT_EMAIL} on taxonomy project: ${PT_PROJECT}"
    gcloud projects add-iam-policy-binding "$PT_PROJECT" \
        --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
        --role="roles/datacatalog.viewer" \
        --condition=None > /dev/null
fi

# --- Create secrets file for local `act` runs ---
echo ""
echo "--- Creating '.secrets' file for local 'act' runs ---"
if ! command -v base64 &> /dev/null
then
    echo "Error: 'base64' command could not be found. Please install it to continue."
    exit 1
fi

# Base64 encode the key file. The syntax is different on macOS and Linux.
if [[ "$(uname)" == "Darwin" ]]; then
  ENCODED_KEY=$(base64 -i "$KEY_FILE")
else
  ENCODED_KEY=$(base64 -w 0 < "$KEY_FILE")
fi

echo "GCP_TEST_SERVICE_ACCOUNT=${ENCODED_KEY}" > .secrets
echo "GCP_PROJECT_ID=${GCP_PROJECT_ID}" >> .secrets
echo "GCP_REGION=${GCP_REGION}" >> .secrets
echo "DBT_POLICY_TAG=${DBT_POLICY_TAG}" >> .secrets
echo "DBT_BIGQUERY_CONNECTION=${DBT_BIGQUERY_CONNECTION}" >> .secrets
echo "GCP_TEST_BUCKET_NAME=${GCP_TEST_BUCKET_NAME}" >> .secrets
echo "'.secrets' file created successfully."

echo ""
echo "✅ Project setup complete."
echo "You can now run the local tests using 'act'." 