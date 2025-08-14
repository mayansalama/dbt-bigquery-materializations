-- depends_on: {{ ref('dbt_export_audit') }}

{{
  config(
    materialized='stored_procedure',
    arguments=[
      {'name': 'source_query', 'type': 'string'},
      {'name': 'model_relation_str', 'type': 'string'},
      {'name': 'uri', 'type': 'string'},
      {'name': 'export_format', 'type': 'string'},
      {'name': 'options_string', 'type': 'string'},
      {'name': 'is_incremental', 'type': 'bool'},
      {'name': 'timestamp_column', 'type': 'string'},
      {'name': 'export_schedule', 'type': 'string'},
      {'name': 'invocation_id', 'type': 'string'}
    ],
    options={
      'strict_mode': false
    },    
    enabled=var('DBT_BQ_MATERIALIZATIONS_ENABLE_EXPORT', false)
  )
}}

{% if execute %}
  {% set audit_table = ref('dbt_export_audit') %}
{% endif %}

begin
  declare last_export_timestamp timestamp;
  declare new_export_timestamp timestamp;
  declare export_sql string;
  declare has_run_recently bool;
  declare custom_job_id string;
  declare computed_export_row_count int64;
  declare schedule_check_sql string;
  declare where_clause string;
  declare export_started_ts timestamp;

  -- create a stable custom job id for this run (needed for skipped logging too)
  set custom_job_id = concat(invocation_id, '::', model_relation_str);

  -- 0. granular schedule check using dynamic date-part in TIMESTAMP_TRUNC
  if export_schedule is not null then
    set schedule_check_sql = format(
      """
      select count(*) > 0
      from {{ audit_table }}
      where model_relation = @model_relation
        and status = 'success'
        and timestamp_trunc(export_completed_at, %s) = timestamp_trunc(current_timestamp(), %s)
      """,
      upper(export_schedule),
      upper(export_schedule)
    );

    execute immediate schedule_check_sql into has_run_recently using model_relation_str as model_relation;

    if has_run_recently then
      insert into {{ audit_table }} (
        dbt_export_run_id,
        model_relation,
        bigquery_job_id,
        uri,
        query_string,
        export_row_count,
        export_started_at,
        export_completed_at,
        data_interval_start,
        data_interval_end,
        status,
        failure_reason
      )
      values (
        generate_uuid(),
        model_relation_str,
        custom_job_id,
        uri,
        null,
        null,
        current_timestamp(),
        current_timestamp(),
        null,
        null,
        'skipped',
        null
      );
      return;
    end if;
  end if;

  -- 1. build the EXPORT DATA statement
  set export_sql = format("""
    export data options(
      uri = '%s',
      format = '%s',
      overwrite = true
      %s
    ) as
    with source_query as (
      %s
    )
    select * from source_query
    """,
    uri,
    export_format,
    coalesce(concat(', ', options_string), ''),
    source_query
  );

  -- 2.1 capture start timestamp and insert 'started'
  set export_started_ts = current_timestamp();

  insert into {{ audit_table }} (
    dbt_export_run_id,
    model_relation,
    bigquery_job_id,
    uri,
    query_string,
    export_row_count,
    export_started_at,
    export_completed_at,
    data_interval_start,
    data_interval_end,
    status
  )
  values (
    generate_uuid(),
    model_relation_str,
    custom_job_id,
    uri,
    null,
    null,
    export_started_ts,
    null,
    null,
    null,
    'started'
  );

  -- 3. single transaction for snapshot consistency (reads only)
  begin
    begin transaction;
      -- compute last successful end watermark from prior runs (may be null on first run)
      set last_export_timestamp = (
        select max(data_interval_end)
        from {{ audit_table }}
        where model_relation = model_relation_str
          and status = 'success'
      );

      -- compute new high watermark from the same snapshot when a timestamp column is provided
      if timestamp_column is not null then
        execute immediate format(
          "select timestamp(max(%s)) from (\n%s\n)", timestamp_column, source_query
        ) into new_export_timestamp;
      end if;

      -- append a bounded filter for incremental runs
      if is_incremental then
        set where_clause = format(
          " where %s > timestamp('%s') and %s <= timestamp('%s')",
          timestamp_column,
          coalesce(cast(last_export_timestamp as string), '1970-01-01'),
          timestamp_column,
          cast(new_export_timestamp as string)
        );
        set export_sql = export_sql || where_clause;
      end if;

      -- compute export row count from the same snapshot using the same filter
      execute immediate format(
        "select count(*) from (with source_query as (\n%s\n) select * from source_query) %s",
        source_query,
        coalesce(where_clause, '')
      ) into computed_export_row_count;

    commit transaction;

    -- BigQuery limitation: EXPORT DATA is not supported inside a multi-statement transaction.
    -- Run the export outside the transaction, then update audit based on outcome.
    begin
      execute immediate export_sql;

      update {{ audit_table }}
      set
        status = 'success',
        export_completed_at = current_timestamp(),
        data_interval_start = last_export_timestamp,
        data_interval_end = new_export_timestamp,
        export_row_count = computed_export_row_count,
        query_string = export_sql,
        failure_reason = null
      where bigquery_job_id = custom_job_id;

    exception when error then
      update {{ audit_table }}
      set
        status = 'fail',
        export_completed_at = current_timestamp(),
        data_interval_start = last_export_timestamp,
        data_interval_end = new_export_timestamp,
        export_row_count = computed_export_row_count,
        query_string = export_sql,
        failure_reason = @@error.message
      where bigquery_job_id = custom_job_id;

      raise;
    end;

  end;

end; 