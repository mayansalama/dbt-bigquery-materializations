{{ config(materialized='table') }}

SELECT
  predicted_label
FROM
  ML.PREDICT(MODEL {{ ref('example_linear_reg_model') }},
    (
      SELECT
        100 AS feature
    )) 