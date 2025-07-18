-- This test compares the output of the Python 'add_one' function
-- with the expected output defined in the 'example_sql_add_one_input' model.
select {{ ref('example_python_add_one') }}(x) as result
from {{ ref('example_sql_add_one_input') }} 