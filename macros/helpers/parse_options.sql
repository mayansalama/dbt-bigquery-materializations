{% macro parse_options(options, reserved_keywords=[]) -%}
  {# Normalize to a mapping if possible #}
  {%- set opts = none -%}
  {%- if options is mapping -%}
    {%- set opts = options -%}
  {%- elif options is string -%}
    {%- set parsed = fromyaml(options) -%}
    {%- if parsed is mapping -%}
      {%- set opts = parsed -%}
    {%- else -%}
      {{ options }}
    {%- endif -%}
  {%- endif -%}

  {%- if opts is not none -%}
    {# Validate reserved keywords #}
    {%- if reserved_keywords and reserved_keywords is sequence -%}
      {%- for k, v in opts.items() -%}
        {%- if k in reserved_keywords -%}
          {%- do exceptions.raise_compiler_error('parse_options: reserved option "' ~ k ~ '" was provided. Reserved: ' ~ reserved_keywords | join(', ')) -%}
        {%- endif -%}
      {%- endfor -%}
    {%- endif -%}

    {# Render mapping #}
    {%- for k, v in opts.items() -%}
      {{ k }}=
      {%- if v is string -%}
        '{{ v }}'
      {%- else -%}
        {{ v }}
      {%- endif -%}
      {%- if not loop.last -%}, {%- endif -%}
    {%- endfor -%}
  {%- endif -%}
{%- endmacro %} 