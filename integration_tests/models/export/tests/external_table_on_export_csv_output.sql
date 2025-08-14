-- depends_on: {{ ref('example_csv_full_export') }}

{{
  config(
    materialized='external_table',
    options={
      "uris": [
        "gs://" ~ env_var('GCP_TEST_BUCKET_NAME') ~ "/example_csv_full_export/" ~ run_started_at.strftime('%Y-%m-%d') ~ "/output-*.csv"
      ],
      "format": "CSV",
      "field_delimiter": "|",
      "skip_leading_rows": 1
    }
  )
}}

id string,
updated_at timestamp 