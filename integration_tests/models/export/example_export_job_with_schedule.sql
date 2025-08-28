-- depends_on: {{ ref('sp_export_data') }}

{{
  config(
    materialized='export_data',
    uri='gs://' ~ env_var('GCP_TEST_BUCKET_NAME') ~ '/' ~ this.name ~ '/' ~ env_var('DBT_BQ_MATERIALIZATIONS_TEST_ID', 'abc') ~ '/*.parquet',
    export_format='PARQUET',
    timestamp_column='updated_at',
    export_schedule='day'
  )
}}

select
  id,
  -- Example of timezone conversion for the timestamp filter column
  datetime(updated_at, 'Australia/Sydney') as updated_at_converted,
  updated_at
from {{ ref('source_data_for_export') }} 
