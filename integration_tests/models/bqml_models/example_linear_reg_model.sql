{{
    config(
        materialized='bqml_model',
        options={
            'model_type': 'LINEAR_REG',
            'input_label_cols': ['label']
        }
    )
}}

SELECT *
FROM {{ ref('bqml_linear_reg_data') }} 