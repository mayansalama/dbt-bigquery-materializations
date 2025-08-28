{% materialization external_table, adapter='bigquery' %}

  {%- set target_relation = this.incorporate(type='table') -%}

  {%- set replace = config.get('replace', default=True) -%}
  {%- set options = config.get('options') -%}
  {%- if options is none -%}
    {{ exceptions.raise_compiler_error("External table materialization requires 'options' config.") }}
  {%- endif -%}
  {%- set uris = options.get('uris') -%}
  {%- if uris is none -%}
    {{ exceptions.raise_compiler_error("The 'uris' option is required for external tables.") }}
  {%- endif -%}
  {%- set partition_by = config.get('partition_by') -%}
  {%- set connection = config.get('connection') -%}
  {# What's the reason for deleting first? #}
  {%- set replace_clause = 'CREATE OR REPLACE' if replace else 'CREATE' -%}

  {{ run_hooks(pre_hooks) }}

  {%- set ddl -%}
    {{ replace_clause }} EXTERNAL TABLE {{ target_relation }}
    {%- if sql | trim -%}
    (
      {{ sql }}
    )
    {%- endif -%}
    {%- if connection %}
      WITH CONNECTION `{{ connection }}`
    {%- endif %}
    {%- if partition_by is not none %}
      WITH PARTITION COLUMNS
      {%- if partition_by is not true -%}
      (
        {%- for p in partition_by -%}
          `{{ p.name }}` {{ p.data_type }}{% if not loop.last %},{% endif %}
        {%- endfor -%}
      )
      {%- endif %}
    {%- endif %}
    OPTIONS (
      {{ dbt_bigquery_materializations.parse_options(options=options) }}
    )
  {%- endset -%}

  {%- call statement('main') -%}
    {{ ddl }}
  {%- endcall -%}

  {%- set has_policy_tags = model.columns | map(attribute='policy_tags') | select() | list | length > 0 -%}
  {%- if has_policy_tags and not connection -%}
    {# would be better to check this before creating the external table at all I think #}
    {{ exceptions.raise_compiler_error(
        "Policy tags are only supported for BigLake tables. Please configure a `connection` for this model."
    ) }}
  {%- endif -%}

  {{ persist_docs(target_relation, model) }}

  {{ run_hooks(post_hooks) }}

  {{ return({'relations': [target_relation]}) }}

{% endmaterialization %} 