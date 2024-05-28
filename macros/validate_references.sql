{% macro validate_production_references() %}
    {%- set errors = [] -%}
    {%- set model = model if model else 'unknown' -%}

    {%- set database_constraints = {
        'STAGING': ['CANON', 'MARTS'],
        'CANON': ['MARTS'],
        'MARTS': []
    } -%}

    {% for relation in adapter.get_relations(database=database, schema=schema) %}
        {% if relation.database in database_constraints.get(database, []) %}
            {% set error_message = "Model {{ model }} references {{ relation.database }} which is not allowed for database {{ database }}" %}
            {% do errors.append(error_message) %}
        {% endif %}
    {% endfor %}

    {%- if errors | length > 0 -%}
        {{ exceptions.raise_compiler_error(errors | join('\n')) }}
    {%- endif -%}
{% endmacro %}
