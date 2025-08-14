-- depends_on: {{ ref('example_export_job') }}
-- depends_on: {{ ref('example_export_job_with_schedule') }}
-- depends_on: {{ ref('example_csv_full_export') }}

{{ config(materialized='table') }}

with staticified as (
  select
    'STATIC' as dbt_export_run_id,
    -- Extract just the model name from the fully qualified relation
    regexp_extract(model_relation, r'`[^`]+`\.`[^`]+`\.`([^`]+)`$') as model_relation,
    'STATIC_JOB' as bigquery_job_id,
    'STATIC_URI' as uri,
    '1970-01-01 00:00:00 UTC' as export_started_at,
    '1970-01-01 00:00:00 UTC' as export_completed_at,
    case when data_interval_start is null then cast(null as string) else '1970-01-01 00:00:00 UTC' end as data_interval_start,
    case when data_interval_end is null then cast(null as string) else '1970-01-01 00:00:00 UTC' end as data_interval_end,
    status,
    export_row_count
  from {{ ref('dbt_export_audit') }}
)
select *
from staticified
