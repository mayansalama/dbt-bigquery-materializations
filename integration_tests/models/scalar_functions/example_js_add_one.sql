// This model demonstrates a simple JavaScript UDF.
// It takes an integer and returns the integer plus one.
{{
  config(
    materialized='function',
    arguments=[
      {'name': 'x', 'type': 'int64'}
    ],
    return_type='int64',
    language='js'
  )
}}

return parseInt(x) + 1; 