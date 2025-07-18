-- This model demonstrates a SQL table-valued function (TVF) with multiple arguments.
-- It filters the `example_external_table_data` seed based on the input name and abbreviation prefixes.
{{
  config(
    materialized='table_function',
    arguments='name_prefix STRING, abbr_prefix STRING',
    return_table='name STRING, post_abbr STRING'
  )
}}

SELECT
  name,
  post_abbr
FROM
  {{ ref('example_external_table_data') }}
WHERE
  STARTS_WITH(name, name_prefix) AND STARTS_WITH(post_abbr, abbr_prefix) 