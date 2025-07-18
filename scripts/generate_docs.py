import yaml
import os

def get_model_description(model_name, example_dir):
    schema_path = os.path.join(example_dir, 'schema.yml')
    if os.path.exists(schema_path):
        with open(schema_path, 'r') as f:
            schema = yaml.safe_load(f)
            for model in schema.get('models', []):
                if model.get('name') == model_name:
                    return model.get('description')
    return None

def generate_docs():
    with open('macros/schema.yml', 'r') as f:
        schema = yaml.safe_load(f)

    with open('README.md', 'w') as f:
        f.write("# dbt-bigquery-materializations\n\n")
        f.write("This package provides materializations for creating and managing BigQuery-specific resources.\n\n")

        materializations = [m for m in schema['macros'] if 'materialization' in m.get('tags', [])]
        other_macros = [m for m in schema['macros'] if 'materialization' not in m.get('tags', [])]

        if materializations:
            f.write("## Materializations\n\n")
            for macro in materializations:
                f.write(f"### `{macro['name']}`\n\n")
                f.write(f"{macro['description']}\n\n")

                example_dir_name = macro['name']
                if macro['name'] == 'function':
                    example_dir_name = 'scalar_functions'
                elif macro['name'] == 'table_function':
                    example_dir_name = 'table_functions'
                elif macro['name'] == 'stored_procedure':
                    example_dir_name = 'stored_procedures'
                elif macro['name'] == 'external_table':
                    example_dir_name = 'external_tables'
                elif macro['name'] == 'call_procedure':
                    example_dir_name = 'stored_procedures'

                example_dir = os.path.join('integration_tests/models', example_dir_name)

                if os.path.isdir(example_dir):
                    f.write("#### Example\n\n")
                    for filename in sorted(os.listdir(example_dir)):
                        if filename.endswith(".sql"):
                            model_name = os.path.splitext(filename)[0]
                            file_path = os.path.join(example_dir, filename)
                            description = get_model_description(model_name, example_dir)
                            f.write(f"- [`{filename}`]({file_path})")
                            if description:
                                f.write(f": {description}")
                            f.write("\n")
                    f.write("\n")

        if other_macros:
            f.write("## Other Macros\n\n")
            for macro in other_macros:
                f.write(f"### `{macro['name']}`\n\n")
                f.write(f"{macro['description']}\n\n")
                if 'arguments' in macro:
                    f.write("#### Arguments\n\n")
                    for arg in macro['arguments']:
                        f.write(f"- `{arg['name']}` ({arg['type']}): {arg['description']}\n")
                    f.write("\n")

if __name__ == '__main__':
    generate_docs() 