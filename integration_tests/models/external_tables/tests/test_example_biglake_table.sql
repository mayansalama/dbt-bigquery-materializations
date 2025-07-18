-- The view is defined as a passthrough to the underlying table
select *
from {{ ref('example_biglake_table') }} 