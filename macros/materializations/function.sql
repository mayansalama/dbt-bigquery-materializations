{% materialization function, adapter='bigquery' %}

  {%- set language = config.get('language', default='sql') | lower -%}
  {%- set valid_languages = ['sql', 'js', 'python'] -%}
  {%- if language not in valid_languages -%}
    {{ exceptions.raise_compiler_error("Invalid language '" ~ language ~ "'. Supported languages are: " ~ valid_languages|join(', ')) }}
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

  {%- set return_type = config.get('return_type') -%}
  {%- if return_type is none -%}
    {{ exceptions.raise_compiler_error("Function materialization requires a 'return_type' config.") }}
  {%- endif -%}
  {%- set description = config.get('description') -%}
  {%- set options = config.get('options') -%}
  {%- set replace = config.get('replace', default=True) -%}

  {%- set target_relation = this.incorporate(type='view') -%}

  {%- set replace_clause = 'CREATE OR REPLACE' if replace else 'CREATE' -%}

  {{ run_hooks(pre_hooks) }}

  {%- set ddl -%}
    {{ replace_clause }} FUNCTION {{ target_relation }} ({{ arguments_str }})
    RETURNS {{ return_type }}
    {% if language != 'sql' -%}
      LANGUAGE {{ language }}
    {%- endif %}
    {%- if description or options %}
    OPTIONS (
      {%- if description %}description="{{ description }}"{%- if options %}, {% endif %}{% endif %}
      {%- if options %}{{ dbt_bigquery_materializations.parse_options(options=options) }}{%- endif %}
    )
    {%- endif %}
    {% if language == 'python' -%}
      AS r"""
        {{ sql }}
      """;
    {%- elif language == 'js' -%}
      AS """
        {{ sql }}
      """;
    {%- else -%}
      AS (
        {{ sql }}
      );
    {%- endif %}
  {%- endset -%}

  {%- call statement('main') -%}
    {{ ddl }}
  {%- endcall -%}

  {{ run_hooks(post_hooks) }}

  {{ return({'relations': [target_relation]}) }}

{% endmaterialization %} 