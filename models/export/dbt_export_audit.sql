-- models/export/dbt_export_audit.sql

{{
  config(
    materialized='incremental',
    full_refresh= None if var('DBT_BQ_MATERIALIZATIONS_AUDIT_FULL_REFRESH', false) else false, 
    enabled=var('DBT_BQ_MATERIALIZATIONS_ENABLE_EXPORT', false)
  )
}}

select
    cast(null as string) as dbt_export_run_id,
    cast(null as string) as model_relation,
    cast(null as string) as bigquery_job_id,
    cast(null as string) as uri,
    cast(null as string) as query_string,
    cast(null as int64) as export_row_count,
    cast(null as timestamp) as export_started_at,
    cast(null as timestamp) as export_completed_at,
    cast(null as timestamp) as data_interval_start,
    cast(null as timestamp) as data_interval_end,
    cast(null as string) as status,
    cast(null as string) as failure_reason
limit 0 