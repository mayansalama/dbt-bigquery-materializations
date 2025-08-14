-- depends_on: {{ ref('example_export_job') }}

-- {{ invocation_id }} putting this here forces a re-parse - note config block usually not re-parsed

{% set uri = "gs://" ~ env_var('GCP_TEST_BUCKET_NAME') ~ "/example_export_job/" ~ invocation_id ~ "/" ~ run_started_at.strftime('%Y-%m-%d') ~ "/*.parquet" %}

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