-- The call_procedure materialization should have resulted in a new table being created.
-- This test will pass if the number of matching tables is 1.

-- This model must be downstream of the call_example_procedure_creator model
-- so that the procedure has been called before this test is run.
{{ config(
  severity = 'error'
) }}

WITH table_count AS (
  SELECT
    COUNT(*) as n
  FROM
    {{ target.database }}.{{ target.schema }}.INFORMATION_SCHEMA.TABLES
  WHERE
    table_name = 'created_by_procedure'
)

SELECT
  *
FROM
  table_count
WHERE n != 1 