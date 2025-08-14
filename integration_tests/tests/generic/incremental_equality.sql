{% test incremental_equality(model, compare_model, compare_columns=None, exclude_columns=None, precision=None) %}
  {% if not flags.FULL_REFRESH %}
    {{ return(
      adapter.dispatch('test_equality', 'dbt_utils')(
        model,
        compare_model,
        compare_columns,
        exclude_columns,
        precision
      )
    ) }}
  {% else %}
    -- Skip test gracefully during full refresh (returns zero rows, passes)
    select null limit 0
  {% endif %}
{% endtest %}