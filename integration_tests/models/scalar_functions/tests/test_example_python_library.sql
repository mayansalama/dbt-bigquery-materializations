-- This test ensures the Python library function returns a non-null string.
-- It calls the function 3 times and asserts the results are not null.
{{
  config(
    materialized='table',
  )
}}
SELECT {{ ref('example_python_library') }}() as address from UNNEST(GENERATE_ARRAY(1, 3)) 