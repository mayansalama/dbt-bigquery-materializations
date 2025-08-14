{{ config(materialized='table') }}

SELECT
  forecast_timestamp,
  forecast_value
FROM
  ML.FORECAST(MODEL {{ ref('example_arima_plus_model') }},
    STRUCT(3 AS horizon, 0.8 AS confidence_level)) 