// This model demonstrates a JavaScript UDF that uses an external library.
{{
  config(
    materialized = 'function',
    options = {
      "library": ["gs://" ~ env_var('GCP_TEST_BUCKET_NAME') ~ "/test_lib.js"]
    },
    language = 'js',
    return_type = 'string'
  )
}}

return getConstant(); 