-- This model demonstrates a stored procedure with a side effect.
-- It creates a new table named `created_by_procedure`.
-- This is used to test that the `call_procedure` materialization
-- correctly executes a procedure.
{{
  config(
    materialized='stored_procedure'
  )
}}

CREATE OR REPLACE TABLE {{ target.database }}.{{ target.schema }}.created_by_procedure (
  id INT64
); 