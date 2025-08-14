# dbt-bigquery-materializations

This package provides materializations for creating and managing BigQuery-specific resources.

## Materializations

### `call_procedure`

Executes CALL <procedure>(…) as a dbt node. Configure the target routine and arguments. Useful for procedures that perform DDL/DML or side effects.

#### Example

- [`example_procedure.sql`](integration_tests/models/stored_procedures/example_procedure.sql): Stored procedure that runs a query.
- [`example_procedure_creator.sql`](integration_tests/models/stored_procedures/example_procedure_creator.sql): Stored procedure with a side effect to create a table.

### `export_data`

Runs the BigQuery EXPORT DATA statement via the `sp_export_data` stored procedure. Configure uri, format, options_string, is_incremental, timestamp_column, and export_schedule. Depends on `dbt_export_audit` and var `DBT_BQ_MATERIALIZATIONS_ENABLE_EXPORT`.

#### Example

- [`example_export_job.sql`](integration_tests/models/export/example_export_job.sql): Exports a model incrementally to PARQUET.
- [`example_export_job_with_schedule.sql`](integration_tests/models/export/example_export_job_with_schedule.sql): Exports incrementally but skips if it already ran in the same day.
- [`example_csv_full_export.sql`](integration_tests/models/export/example_csv_full_export.sql): Full export to CSV with header and custom delimiter.

### `external_table`

Materialization for BigQuery CREATE EXTERNAL TABLE (including BigLake). Configure table OPTIONS (for example, uris, format, schema, connection). BigLake tables require a BigQuery connection resource.

#### Example

- [`example_external_table.sql`](integration_tests/models/external_tables/example_external_table.sql): Standard external table for querying data in Google Cloud Storage without a BigQuery connection.
- [`example_biglake_table.sql`](integration_tests/models/external_tables/example_biglake_table.sql): External table using a BigQuery connection, allowing fine-grained access control with policy tags.

### `function`

Materialization for CREATE FUNCTION (scalar UDF). Supports SQL, JavaScript, and Python. Configure language/body and function OPTIONS; the SELECT defines returned value(s).

#### Example

- [`example_sql_add_one.sql`](integration_tests/models/scalar_functions/example_sql_add_one.sql): Simple SQL UDF that adds one to an integer.
- [`example_js_add_one.sql`](integration_tests/models/scalar_functions/example_js_add_one.sql): Simple JavaScript UDF that adds one to an integer.
- [`example_js_library.sql`](integration_tests/models/scalar_functions/example_js_library.sql): JavaScript UDF that uses an external library from Google Cloud Storage.
- [`example_python_add_one.sql`](integration_tests/models/scalar_functions/example_python_add_one.sql): Simple Python UDF that adds one to an integer.
- [`example_python_library.sql`](integration_tests/models/scalar_functions/example_python_library.sql): Python UDF that uses an external library from PyPI.

### `model`

Materialization for BigQuery ML CREATE MODEL. Configure OPTIONS (for example, model_type) and provide an AS SELECT training query.

#### Example

- [`example_linear_reg_model.sql`](integration_tests/models/bqml_models/example_linear_reg_model.sql): A simple linear regression model to predict a label based on a single feature.
- [`example_arima_plus_model.sql`](integration_tests/models/bqml_models/example_arima_plus_model.sql): An ARIMA-based time-series forecasting model.

### `stored_procedure`

Materialization for CREATE PROCEDURE. Configure the routine signature (arguments) and a GoogleSQL body (multi‑statement supported). No special dependencies.

#### Example

- [`example_procedure.sql`](integration_tests/models/stored_procedures/example_procedure.sql): Stored procedure that runs a query.
- [`example_procedure_creator.sql`](integration_tests/models/stored_procedures/example_procedure_creator.sql): Stored procedure with a side effect to create a table.

### `table_function`

Materialization for CREATE TABLE FUNCTION (TVF). SQL only. Configure arguments and the RETURNS TABLE query that defines the output schema and rows.

#### Example

- [`example_table_function.sql`](integration_tests/models/table_functions/example_table_function.sql): Simple table-valued function that returns a table.
- [`example_table_function_string_args.sql`](integration_tests/models/table_functions/example_table_function_string_args.sql): Table-valued function that accepts string arguments.

## Other Macros

### `parse_options`

Helper macro to render key=value pairs for BigQuery OPTIONS clauses from a mapping or YAML string. Validates reserved keywords when provided.

#### Arguments

- `options` (dict or string): A dictionary or a YAML string containing the options to be parsed.

# Installation and Configuration

To use this package, add it to your `packages.yml`:

```yaml
packages:
  - git: "https://github.com/mayansalama/dbt-bigquery-materializations"
    # revision: <main or specific git tag>
```

By default, the export models are disabled. You can enable them and/or change identifiers (schema, alias) in your `dbt_project.yml`:

```yaml
models:
  dbt_bigquery_materializations:
    +enabled: true # or false to disable
    export:
      +schema: my_audit_schema # Optional: changes the schema
      dbt_export_audit:
        +alias: my_export_audit_log # Optional: changes the table name
      sp_export_data:
        +alias: my_export_procedure # Optional: changes the procedure name
```

## Utility Models

This package includes reusable models to provide additional functionality. These models can be configured or disabled in your `dbt_project.yml`.

### `dbt_export_audit`

A log table that tracks the status and metadata of dbt-driven data exports.

### `sp_export_data`

A stored procedure that handles stateful, incremental exports of data from a source table to an external location like GCS.

#### Arguments

- `source_query` (string): The SQL query that defines the data to be exported.
- `model_relation_str` (string): The string representation of the dbt model relation (`{{ this }}`), used for logging in the audit table.
- `uri` (string): The Google Cloud Storage URI where the exported files will be written.
- `export_format` (string): The format of the exported files (e.g., `PARQUET`, `CSV`).
- `export_options` (array<struct<name string, value string>>): An array of key-value pairs for export options (e.g., `field_delimiter`).
- `is_incremental` (bool): A boolean flag indicating whether the export should be incremental.
- `timestamp_column` (string): The name of the timestamp column used for incremental exports.
- `export_schedule` (string): A date-part granularity to limit repeated exports within the same period. Accepted values: `minute`, `hour`, `day`.
- `invocation_id` (string): The dbt invocation id for this run; used to construct a stable custom job id for audit updates.

#### Configuration

##### `DBT_BQ_MATERIALIZATIONS_AUDIT_FULL_REFRESH`

- **Type**: `boolean`
- **Default**: `false`

This variable controls the materialization behavior of the `dbt_export_audit` table. When set to `true`, the audit table will be completely rebuilt on every run. This is useful for testing environments where a clean slate is desired for each test run. In production, this should be left as `false` to maintain a persistent audit log.

##### `DBT_BQ_MATERIALIZATIONS_ENABLE_EXPORT_PROCS`

- **Type**: `boolean`
- **Default**: `false`

This variable controls whether the export-related models and procedures (`dbt_export_audit` and `sp_export_data`) are enabled. To use the export functionality, set this variable to `true` in your `dbt_project.yml`. 

