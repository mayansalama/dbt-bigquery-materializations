-- depends_on: {{ ref('example_export_job_with_schedule') }}

-- Same ID for both initial and incremental test
{% set test_id = env_var('DBT_BQ_MATERIALIZATIONS_TEST_ID', 'abc') %}
{% set uri = "gs://" ~ env_var('GCP_TEST_BUCKET_NAME') ~ "/example_export_job_with_schedule/" ~ test_id ~ "/*.parquet" %}

{{
  config(
    materialized='external_table',
    options={
      "uris": [uri],
      "format": "PARQUET"
    }
  )
}}

id string,
updated_at timestamp 
