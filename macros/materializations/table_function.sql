{% materialization table_function, adapter='bigquery' %}

  {%- set language = config.get('language', default='sql') | lower -%}
  {%- if language != 'sql' -%}
    {{ exceptions.raise_compiler_error("Invalid language '" ~ language ~ "'. BigQuery table functions currently only support SQL.") }}
  {%- endif -%}

  {%- set arguments = config.get('arguments', []) -%}
  {%- set arguments_str = '' -%}
  {%- if arguments is string -%}
    {%- set arguments_str = arguments -%}
  {%- elif arguments is iterable -%}
    {%- set argument_list = [] -%}
    {%- for arg in arguments -%}
      {%- if arg.name is not defined or arg.type is not defined -%}
        {{ exceptions.raise_compiler_error("Invalid argument definition in " ~ this ~ ". Each argument must have a 'name' and a 'type'. Got: " ~ arg) }}
      {%- endif -%}
      {%- do argument_list.append(arg.name ~ " " ~ arg.type) -%}
    {%- endfor -%}
    {%- set arguments_str = argument_list | join(', ') -%}
  {%- endif -%}

  {%- set return_table = config.get('return_table') -%}
  {%- if return_table is none -%}
    {{ exceptions.raise_compiler_error("Table function materialization requires a 'return_table' config.") }}
  {%- endif -%}
  {%- set description = config.get('description') -%}
  {%- set options = config.get('options') -%}
  {%- set replace = config.get('replace', default=True) -%}

  {%- set target_relation = this.incorporate(type='view') -%}

  {%- set replace_clause = 'CREATE OR REPLACE' if replace else 'CREATE' -%}

  {{ run_hooks(pre_hooks) }}

  {%- set ddl -%}
    {{ replace_clause }} TABLE FUNCTION {{ target_relation }} ({{ arguments_str }})
    RETURNS TABLE<{{ return_table }}>
    {%- if description or options %}
    OPTIONS (
      {%- if description %}description="{{ description }}"{%- if options %}, {% endif %}{% endif %}
      {%- if options %}{{ dbt_bigquery_materializations.parse_options(options=options) }}{%- endif %}
    )
    {%- endif %}
    AS (
      {{ sql }}
    );
  {%- endset -%}

  {%- call statement('main') -%}
    {{ ddl }}
  {%- endcall -%}

  {{ run_hooks(post_hooks) }}

  {{ return({'relations': [target_relation]}) }}

{% endmaterialization %} 