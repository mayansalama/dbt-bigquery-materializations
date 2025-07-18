-- This model demonstrates a simple stored procedure.
-- It takes an argument but has no side effects.
-- Its purpose is to test that the `stored_procedure` materialization
-- successfully creates a procedure in BigQuery.
{{
  config(
    materialized='stored_procedure',
    arguments=[
      {'name': 'arg1', 'type': 'INT64'}
    ]
  )
}}

-- This is a sample stored procedure
-- It doesn't do anything, it's just for testing
SELECT 1; 