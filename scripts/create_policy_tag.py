import os
from google.cloud import datacatalog_v1
from google.api_core import exceptions

def create_or_get_policy_tag():
    """
    Finds or creates a specific taxonomy and policy tag for testing.

    This script ensures that a consistent, predefined taxonomy and policy tag
    are available for integration tests. It first checks if the resources
    already exist and, if not, creates them. This makes the setup process
    idempotent and avoids creating numerous duplicate resources.

    It prints the full resource name of the policy tag to standard output.
    """
    try:
        project_id = os.environ["GCP_PROJECT_ID"]
        location = os.environ["GCP_REGION"]
    except KeyError as e:
        print(f"Error: Missing required environment variable {e}")
        exit(1)

    taxonomy_display_name = "dbt_materializations_test_taxonomy"
    policy_tag_display_name = "pii_test_tag"
    parent = f"projects/{project_id}/locations/{location}"

    client = datacatalog_v1.PolicyTagManagerClient()

    # 1. Find or create the taxonomy
    taxonomy_name = ""
    try:
        # Check if the taxonomy already exists
        for taxonomy in client.list_taxonomies(parent=parent):
            if taxonomy.display_name == taxonomy_display_name:
                taxonomy_name = taxonomy.name
                print(f"Found existing taxonomy: {taxonomy_name}")
                break
        
        # If not found, create it
        if not taxonomy_name:
            print(f"Creating data catalog taxonomy: {taxonomy_display_name}")
            taxonomy = datacatalog_v1.Taxonomy()
            taxonomy.display_name = taxonomy_display_name
            taxonomy.description = "Test taxonomy for dbt-bigquery-materializations"
            created_taxonomy = client.create_taxonomy(parent=parent, taxonomy=taxonomy)
            taxonomy_name = created_taxonomy.name
            print(f"Created taxonomy: {taxonomy_name}")

    except exceptions.GoogleAPICallError as e:
        print(f"Error managing taxonomy: {e}")
        exit(1)

    # 2. Find or create the policy tag
    policy_tag_name = ""
    try:
        # Check if the policy tag already exists
        for policy_tag in client.list_policy_tags(parent=taxonomy_name):
            if policy_tag.display_name == policy_tag_display_name:
                policy_tag_name = policy_tag.name
                print(f"Found existing policy tag: {policy_tag_name}")
                break

        # If not found, create it
        if not policy_tag_name:
            print(f"Creating policy tag: {policy_tag_display_name}")
            policy_tag = datacatalog_v1.PolicyTag()
            policy_tag.display_name = policy_tag_display_name
            policy_tag.description = "A test policy tag for PII"
            created_policy_tag = client.create_policy_tag(
                parent=taxonomy_name, policy_tag=policy_tag
            )
            policy_tag_name = created_policy_tag.name
            print(f"Created policy tag: {policy_tag_name}")

    except exceptions.GoogleAPICallError as e:
        print(f"Error managing policy tag: {e}")
        exit(1)

    # 3. Print the final policy tag resource name to stdout
    print(policy_tag_name)

if __name__ == "__main__":
    create_or_get_policy_tag() 