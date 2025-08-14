{% materialization bqml_model, adapter='bigquery' %}
  {%- set identifier = model['alias'] -%}

  {%- set old_relation = adapter.get_relation(identifier=identifier,
                                              schema=schema,
                                              database=database) -%}
  {%- set target_relation = api.Relation.create(identifier=identifier,
                                                 schema=schema,
                                                 database=database,
                                                 type='table') -%}

  {{ run_hooks(pre_hooks, inside_transaction=False) }}

  -- `BEGIN` happens here:
  {{ run_hooks(pre_hooks, inside_transaction=True) }}

  -- build model
  {%- call statement('main') -%}
    {{ dbt_bigquery_materializations.bigquery__create_model_as(target_relation, sql) }}
  {%- endcall -%}

  {{ run_hooks(post_hooks, inside_transaction=True) }}

  -- `COMMIT` happens here
  {{ adapter.commit() }}

  {{ run_hooks(post_hooks, inside_transaction=False) }}

  {{ return({'relations': [target_relation]}) }}
{% endmaterialization %}

{% macro bigquery__create_model_as(relation, sql) -%}
  {%- set transform_statement = config.get('transform_statement') -%}
  {%- set options = config.get('options', {}) -%}

  CREATE OR REPLACE MODEL {{ relation.render() }}
  {%- if transform_statement is not none %}
  TRANSFORM(
    {{ transform_statement | indent(4) }}
  )
  {%- endif %}
  {%- if options %}
  OPTIONS (
    {{ dbt_bigquery_materializations.parse_options(options) }}
  )
  {%- endif %}
  AS (
    {{ sql }}
  )
{%- endmacro %} 