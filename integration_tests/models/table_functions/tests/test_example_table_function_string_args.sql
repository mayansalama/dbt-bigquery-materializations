-- This test calls the multi-argument TVF and compares the result to the expected output.
select * from {{ ref('example_table_function_string_args') }}('New', 'N')
where name = 'New York' 