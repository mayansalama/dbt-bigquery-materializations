-- depends_on: {{ ref('source_data_for_export') }}
-- depends_on: {{ ref('sp_export_data') }}

{{
  config(
    materialized='export_data',
    uri='gs://' ~ env_var('GCP_TEST_BUCKET_NAME') ~ '/' ~ this.name ~ '/' ~ invocation_id ~ '/' ~ run_started_at.strftime('%Y-%m-%d') ~ '/*.parquet',
    export_format='PARQUET',
    timestamp_column='updated_at',
  )
}}

select * from {{ ref("source_data_for_export") }} 
