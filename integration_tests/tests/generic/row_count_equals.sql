{% test row_count_equals(model, value) %}
with row_counts as (
  select count(*) as row_count from {{ model }}
)
select * from row_counts where row_count != {{ value }}
{% endtest %} 