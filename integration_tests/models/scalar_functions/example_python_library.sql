# This model demonstrates a Python UDF that uses an external library.
# It returns a random address using the 'faker' library.
{{
    config(
        materialized='function',
        return_type='string',
        options={
            "packages": ["faker"],
            "description": "returns a random address using faker for python",
            "entry_point": "generate_address",
            "runtime_version": "python-3.11"
        },
        language="python"
    )
}}
from faker import Faker

def generate_address():
  fake = Faker()
  return fake.address() 