# Contributing to dbt-bigquery-materializations

This guide provides instructions for setting up a local development environment to contribute to this project.

## Contributing Process

1. Fork the repository to your GitHub account
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR-USERNAME/dbt-bigquery-materializations.git
   cd dbt-bigquery-materializations
   ```
3. Add the upstream repository as a remote:
   ```bash
   git remote add upstream https://github.com/mayansalama/dbt-bigquery-materializations.git
   ```
4. Create a new branch for your changes:
   ```bash
   git checkout -b feature/your-feature-name
   ```
5. Make your changes and commit them with clear, descriptive commit messages
6. Push to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```
7. Open a Pull Request from your fork to the main repository
8. Ensure all checks pass and address any review comments

Remember to keep your fork up to date:
```bash
git fetch upstream
git checkout main
git merge upstream/main
```

## Local Development Setup

### Prerequisites

1.  **Google Cloud SDK**: Make sure you have `gcloud` installed and authenticated with a user account that has admin perms on the below APIs. 
2.  **Enable GCP APIs**: Before running the setup script, you must manually enable the following APIs for your GCP project.
    - [BigQuery API](https://console.cloud.google.com/apis/library/bigquery.googleapis.com)
    - [Cloud Storage API](https://console.cloud.google.com/apis/library/storage.googleapis.com)
    - [Data Catalog API](https://console.cloud.google.com/apis/library/datacatalog.googleapis.com)
        (Need to change to dataplex)
    - [BigQuery Connection API](https://console.cloud.google.com/apis/library/bigqueryconnection.googleapis.com)
3.  **Python**: Make sure you have `python`, `pip` (and for this guide `uv`)
4.  **Docker**: Docker Desktop must be installed and running.
5.  **act**: Install `act` to run GitHub Actions locally. See the [official installation guide](https://github.com/nektos/act#installation).

### Local Environment Setup with `uv`

For a faster setup experience, you can use `uv` to create and manage your virtual environment.

1.  **Create and activate the virtual environment**:
    ```bash
    uv venv
    source .venv/bin/activate
    ```

2.  **Install dependencies**:
    This command will install the necessary packages for running the integration tests.
    ```bash
    uv pip install dbt-bigquery google-cloud-datacatalog PyYAML
    ```

### One-Time Project Setup

Before you can run the integration tests locally for the first time, you need to set up the necessary GCP resources. A bash script is provided to automate this.

1.  **Set your GCP Details**:
    ```bash
    export GCP_PROJECT_ID="your-gcp-project-id"
    export GCP_REGION="australia-southeast1"  # Defaults to EU if not set
    ```
2.  **Log in to GCP**:
    ```bash
    gcloud auth login
    ```
3.  **Run the setup script**:
    This script will:
    - Create a dedicated GCP Service Account (`dbt-materializations-ci`).
    - Assign it the necessary `BigQuery Admin`, `Storage Admin`, and `Data Catalog Admin` roles.
    - Create and download a JSON key file named `local-gcloud-creds.json`.
    - Create a GCS bucket for test files.
    - Install required Python packages (`google-cloud-datacatalog`).
    - Run a Python script to create a policy tag taxonomy and a policy tag for testing.
    - Create a `.secrets` file in the project root containing the service account key, project ID, and the newly created policy tag for `act` to use.

    ```bash
    sh scripts/project-setup.sh
    ```
    The script is idempotent. If the service account and key file already exist, it will skip those creation steps.

## Running dbt Commands Directly

You can also run dbt commands directly against your BigQuery project. This is useful for development and for running specific models or tests.

1.  **Export the secrets as environment variables**:
    The `.secrets` file is generated in a `KEY=VALUE` format that is not directly compatible with the `source` command. To load the variables into your shell, you can use the following command, which reads each line from the file and exports it as an environment variable:
    ```bash
    export $(cat .secrets | xargs)
    ```
2.  **Navigate to the integration tests directory**:
    ```bash
    cd integration_tests
    ```
3.  **Run dbt**:
    You can now run any dbt command, for example:
    ```bash
    # Initial setup and test
    dbt build --full-refresh
    # Incremental test
    dbt build
    ```

## Running Integration Tests Locally

Once the one-time setup is complete, you can run the integration tests using `act`. `act` will simulate the GitHub Actions CI environment and use the variables defined in the `.secrets` file.

**Execute the test command:**
```bash
act pull_request --secret-file .secrets --container-architecture linux/amd64 -P ubuntu-latest=catthehacker/ubuntu:act-latest
```

## Updating the README

The `README.md` file is auto-generated from the `macros/schema.yml` file and example models in the `integration_tests/` directory. To update the documentation, modify the `macros/schema.yml` file or the relevant example model, and then run the following command to regenerate the `README.md`:

```bash
python scripts/generate_docs.py
```

## CI/CD

The integration tests are run automatically on push and pull request events to the `main` branch using GitHub Actions. The workflow is defined in `.github/workflows/integration-tests.yml`.
The CI workflow uses the `GCP_TEST_SERVICE_ACCOUNT` secret, which should be the base64-encoded content of a service account key file. 
