-- This test calls the simple TVF and compares the result to the expected output.
select *
from {{ ref('example_table_function') }}('New')
where name = 'New York' 