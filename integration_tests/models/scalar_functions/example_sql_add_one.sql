-- This model demonstrates a simple SQL UDF.
-- It takes an integer and returns the integer plus one.
{{
    config(
        materialized='function',
        arguments='x int64',
        return_type='int64'
    )
}}

x + 1
