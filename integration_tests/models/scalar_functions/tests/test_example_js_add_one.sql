-- This test compares the output of the JS 'add_one' function
-- with the expected output defined in the 'example_sql_add_one_input' model.
select CAST({{ ref('example_js_add_one') }}(x) AS INT64) as result
from {{ ref('example_sql_add_one_input') }} 