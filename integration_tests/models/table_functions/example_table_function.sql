-- This model demonstrates a simple SQL table-valued function (TVF).
-- It filters the `example_external_table_data` seed based on the input `name_prefix`.
{{
  config(
    materialized='table_function',
    arguments=[
      {'name': 'name_prefix', 'type': 'STRING'}
    ],
    return_table='name STRING, post_abbr STRING'
  )
}}

SELECT
  name,
  post_abbr
FROM
  {{ ref('example_external_table_data') }}
WHERE
  STARTS_WITH(name, name_prefix) 