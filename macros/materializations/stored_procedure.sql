{% materialization stored_procedure, adapter='bigquery' %}
  {%- set identifier = model['alias'] -%}
  {%- set non_destructive_mode = (flags.NON_DESTRUCTIVE == True) -%}

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

  {%- set exists_as_table = (old_relation is not none and old_relation.is_table) -%}
  {%- set exists_as_view = (old_relation is not none and old_relation.is_view) -%}

  {%- if non_destructive_mode -%}
    {%- if old_relation is not none -%}
      {{ exceptions.relation_wrong_type(old_relation, 'table') }}
    {%- endif -%}
  {%- endif -%}

  -- build model
  {%- call statement('main') -%}
    {{ dbt_bigquery_materializations.bigquery__create_procedure_as(target_relation, sql) }}
  {%- endcall -%}

  {{ run_hooks(post_hooks, inside_transaction=True) }}

  -- `COMMIT` happens here
  {{ adapter.commit() }}

  {{ run_hooks(post_hooks, inside_transaction=False) }}

  {{ return({'relations': [target_relation]}) }}
{% endmaterialization %}

{% macro bigquery__create_procedure_as(relation, sql) -%}
  {%- set contract_config = config.get('contract') -%}

  CREATE OR REPLACE PROCEDURE {{ relation.render() }}(
    {%- for arg in config.get('arguments', []) -%}
      {{ arg.name }} {{ arg.type }}{% if not loop.last %},{% endif %}
    {%- endfor -%}
  )
  {%- if config.get('options') is not none -%}
    OPTIONS(
      {%- for key, value in config.get('options', {}).items() -%}
        {{ key }}={{ value }}{% if not loop.last %},{% endif %}
      {%- endfor -%}
    )
  {%- endif %}
  BEGIN
    {{ sql }}
  END;
{%- endmacro %} 