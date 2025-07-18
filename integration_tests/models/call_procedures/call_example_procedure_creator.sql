-- This model demonstrates how to use the `call_procedure` materialization.
-- It executes the `example_procedure_creator` procedure.
{{
  config(
    materialized='call_procedure'
  )
}}

CALL {{ ref('example_procedure_creator') }}(); 