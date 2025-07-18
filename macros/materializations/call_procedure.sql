{% materialization call_procedure, adapter='bigquery' %}
  {%- call statement('main') -%}
    {{ sql }}
  {%- endcall -%}
 
  {{ return({'relations': []}) }}
{% endmaterialization %} 