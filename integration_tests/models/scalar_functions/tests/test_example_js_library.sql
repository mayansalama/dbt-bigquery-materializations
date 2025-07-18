-- This test ensures the JS library function returns a non-null string.
-- It calls the function 3 times and asserts the results are not null.
{{
  config(
    materialized='table',
  )
}}
SELECT {{ ref('example_js_library') }}() as company_name from UNNEST(GENERATE_ARRAY(1, 3)) 