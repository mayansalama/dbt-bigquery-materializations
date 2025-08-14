{{
    config(
        materialized='bqml_model',
        options={
            'model_type': 'ARIMA_PLUS',
            'time_series_timestamp_col': 'date_col',
            'time_series_data_col': 'sales',
            'time_series_id_col': 'id'
        }
    )
}}

SELECT
  CAST(date AS TIMESTAMP) AS date_col,
  sales,
  'product_1' as id
FROM {{ ref('bqml_arima_plus_data') }} 