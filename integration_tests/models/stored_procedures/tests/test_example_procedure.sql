-- This test confirms that the `example_procedure` was successfully created.
-- It checks the INFORMATION_SCHEMA for a routine with the correct name.
-- This test will pass if the number of matching procedures is 1.

WITH proc_count AS (
  SELECT
    COUNT(*) as n
  FROM
    {{ ref('example_procedure').database }}.{{ ref('example_procedure').schema }}.INFORMATION_SCHEMA.ROUTINES
  WHERE
    specific_name = '{{ ref('example_procedure').identifier }}'
    AND routine_type = 'PROCEDURE'
)

SELECT
  *
FROM
  proc_count
WHERE n != 1 