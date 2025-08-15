{% materialization export_data, adapter='bigquery' %}
  {%- if not var('DBT_BQ_MATERIALIZATIONS_ENABLE_EXPORT', false) -%}
    {%- do exceptions.raise_compiler_error('export_data materialization requires var "DBT_BQ_MATERIALIZATIONS_ENABLE_EXPORT" = true') -%}
  {%- endif -%}

  {%- set source_query = sql -%}

  {%- set uri = config.get('uri') -%}
  {%- set export_format = config.get('export_format') -%}
  {%- set export_options = config.get('export_options') -%}
  {%- set is_incremental = config.get('is_incremental', (not flags.FULL_REFRESH)) -%}
  {%- set timestamp_column = config.get('timestamp_column') -%}
  {%- set export_schedule = config.get('export_schedule') -%}
  {%- set invocation_id_cfg = config.get('invocation_id', invocation_id) -%}
  {%- set model_relation_str = config.get('model_relation_str', this) -%}

  {%- if uri is none or uri == '' -%}
    {%- do exceptions.raise_compiler_error('export_data: config "uri" is required') -%}
  {%- endif -%}
  {%- if export_format is none or export_format == '' -%}
    {%- do exceptions.raise_compiler_error('export_data: config "export_format" is required') -%}
  {%- endif -%}
  {%- if is_incremental and (timestamp_column is none or timestamp_column == '') -%}
    {%- set is_incremental = false -%}
  {%- endif -%}

  {{ run_hooks(pre_hooks) }}

  {%- set reserved = ['uri', 'format', 'overwrite'] -%}
  {%- set options_string = dbt_bigquery_materializations.parse_options(export_options, reserved) -%}
  {%- set call_sql -%}
    CALL {{ ref('sp_export_data') }}(
      source_query => '''{{ source_query }}''',
      model_relation_str => '{{ model_relation_str }}',
      uri => '{{ uri }}',
      export_format => '{{ export_format }}',
      options_string => {{ "'" ~ (options_string | replace("'", "\\'")) ~ "'" if options_string else 'null' }},
      is_incremental => {{ 'true' if is_incremental else 'false' }},
      timestamp_column => {{ "'" ~ timestamp_column ~ "'" if timestamp_column else 'null' }},
      export_schedule => {{ "'" ~ export_schedule ~ "'" if export_schedule else 'null' }},
      invocation_id => '{{ invocation_id_cfg }}'
    );
  {%- endset -%}

  {%- call statement('main') -%}
    {{ call_sql }}
  {%- endcall -%}

  {{ run_hooks(post_hooks) }}

  {{ return({'relations': []}) }}
{% endmaterialization %} 