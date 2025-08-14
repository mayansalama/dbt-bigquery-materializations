import yaml
import os


def generate_model_docs(f):
    model_schema_path = 'models/export/schema.yml'
    if os.path.exists(model_schema_path):
        with open(model_schema_path, 'r') as schema_file:
            schema = yaml.safe_load(schema_file)
            if schema.get('models'):
                f.write("## Utility Models\n\n")
                f.write("This package includes reusable models to provide additional functionality. These models can be configured or disabled in your `dbt_project.yml`.\n\n")

                for model in schema['models']:
                    f.write(f"### `{model['name']}`\n\n")
                    f.write(f"{model['description']}\n\n")


def write_install_and_config(f):
    f.write("# Installation and Configuration\n\n")
    f.write("To use this package, add it to your `packages.yml`:\n\n")
    f.write("```yaml\n")
    f.write("packages:\n")
    f.write("  - git: \"https://github.com/mayansalama/dbt-bigquery-materializations\"\n")
    f.write("    # revision: <main or specific git tag>\n")
    f.write("```\n\n")
    f.write("By default, the export models are disabled. You can enable them and/or change identifiers (schema, alias) in your `dbt_project.yml`:\n\n")
    f.write("```yaml\n")
    f.write("models:\n")
    f.write("  dbt_bigquery_materializations:\n")
    f.write("    +enabled: true # or false to disable\n")
    f.write("    export:\n")
    f.write("      +schema: my_audit_schema # Optional: changes the schema\n")
    f.write("      dbt_export_audit:\n")
    f.write("        +alias: my_export_audit_log # Optional: changes the table name\n")
    f.write("      sp_export_data:\n")
    f.write("        +alias: my_export_procedure # Optional: changes the procedure name\n")
    f.write("```\n\n")


def generate_docs():
    with open('macros/schema.yml', 'r') as f:
        schema = yaml.safe_load(f)

    with open('README.md', 'w') as f:
        f.write("# dbt-bigquery-materializations\n\n")
        f.write("This package provides materializations for creating and managing BigQuery-specific resources.\n\n")

        macros = schema.get('macros', [])
        # Known materialization macro names (including export_data)
        known_mat_names = set(['export_data', 'external_table', 'function', 'table_function', 'stored_procedure', 'call_procedure', 'bqml_model'])

        # Materializations by name present in schema
        mat_by_name = {m.get('name'): m for m in macros if m.get('name') in known_mat_names}

        # Materializations section
        if mat_by_name:
            f.write("## Materializations\n\n")
            for name in sorted(mat_by_name.keys()):
                macro = mat_by_name[name]
                f.write(f"### `{macro['name']}`\n\n")
                f.write(f"{macro.get('description', '')}\n\n")

                examples_meta = macro.get('examples', [])
                if examples_meta:
                    f.write("#### Example\n\n")
                    for ex in examples_meta:
                        path = ex.get('path', '')
                        filename = os.path.basename(path) if path else ''
                        desc = ex.get('description', '')
                        if path and filename:
                            # Validate path exists
                            if os.path.exists(path):
                                f.write(f"- [`{filename}`]({path})")
                            else:
                                f.write(f"- `{filename}` (missing: {path})")
                            if desc:
                                f.write(f": {desc}")
                            f.write("\n")
                    f.write("\n")

        # Other Macros (non-materializations)
        other_macros = [m for m in macros if m.get('name') not in mat_by_name]
        if other_macros:
            f.write("## Other Macros\n\n")
            for macro in other_macros:
                f.write(f"### `{macro['name']}`\n\n")
                f.write(f"{macro.get('description', '')}\n\n")
                if 'arguments' in macro:
                    f.write("#### Arguments\n\n")
                    for arg in macro['arguments']:
                        f.write(f"- `{arg['name']}` ({arg['type']}): {arg['description']}\n")
                    f.write("\n")

        # Top-level installation/configuration
        write_install_and_config(f)

        # Models last
        generate_model_docs(f)

if __name__ == '__main__':
    generate_docs() 