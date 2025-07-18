{% macro parse_options(options) -%}
  {%- if options is mapping -%}
    {%- for k, v in options.items() -%}
      {{ k }}=
      {%- if v is string -%}
        '{{ v }}'
      {%- else -%}
        {{ v }}
      {%- endif -%}
      {%- if not loop.last -%}, {%- endif -%}
    {%- endfor -%}
  {%- else -%}
    {%- set parsed = options | fromyaml -%}
    {%- if parsed is mapping -%}
      {%- for k, v in parsed.items() -%}{{ k }}={{ v }}{%- if not loop.last -%}, {%- endif -%}{%- endfor -%}
    {%- else -%}
      {{ options }}
    {%- endif -%}
  {%- endif -%}
{%- endmacro %} 