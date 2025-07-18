# This model demonstrates a simple Python UDF.
# It takes an integer and returns the integer plus one.
{{
    config(
        materialized='function',
        arguments='x int64',
        return_type='int64',
        options={
            "description": "adds one to the input number",
            "entry_point": "add_one",
            "runtime_version": "python-3.11"
        },
        language="python"
    )
}}

def add_one(x):
  return x + 1  
