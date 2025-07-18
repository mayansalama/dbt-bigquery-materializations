-- This model demonstrates how to create a standard external table
-- that reads data directly from Google Cloud Storage.
{{
  config(
    materialized = 'external_table',
    options = {
      "format": "CSV",
      "uris": ["gs://" ~ env_var('GCP_TEST_BUCKET_NAME') ~ "/example_external_table_data.csv"]
    }
  )
}}

name STRING OPTIONS(description="State name"),
post_abbr STRING OPTIONS(description="Post abbreviation") 