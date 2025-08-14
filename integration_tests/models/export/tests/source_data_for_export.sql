{{
  config(
    materialized='incremental',
    unique_key='id'
  )
}}

select
  {{ dbt_utils.generate_surrogate_key(['current_timestamp()']) }} as id,
  current_timestamp() as updated_at
