-- depends_on: {{ ref('sp_export_data') }}

{{
  config(
    materialized='export_data',
    uri='gs://' ~ env_var('GCP_TEST_BUCKET_NAME') ~ '/' ~ this.name ~ '/' ~ run_started_at.strftime('%Y-%m-%d') ~ '/output-*.csv',
    export_format='CSV',
    export_options={"header": true, "field_delimiter": "|"}
  )
}}

-- Full export without a timestamp filter
select * from {{ ref('source_data_for_export') }} limit 1