-- This model demonstrates how to create a BigLake external table,
-- which enables features like policy tags. It requires a connection to be configured.
{{
  config(
    materialized='external_table',
    options={
      'uris': ["gs://" + env_var('GCP_PROJECT_ID') + "-bq-mat-tests/sample_external_table_data.csv"],
      'format': 'CSV',
      'skip_leading_rows': 1
    },
    connection=env_var('DBT_BIGQUERY_CONNECTION')
  )
}}
name string,
value int64 
