{% macro validate_production_references() %}
    {% set database_constraints = {
        'STAGING': ['CANON', 'MARTS'],
        'CANON': ['MARTS'],
        'MARTS': []
    } %}

    {% set errors = [] %}

    {% for model in graph.nodes.values() %}
        {% if model.resource_type == 'model' %}
            {% set model_database = model.database %}
            {% set model_references = model.refs | map(attribute='database') | list %}

            {% for reference in model_references %}
                {% if reference in database_constraints[model_database] %}
                    {% set error_message = "Model {{ model.unique_id }} references {{ reference }} which is not allowed for database {{ model_database }}" %}
                    {% do errors.append(error_message) %}
                {% endif %}
            {% endfor %}
        {% endif %}
    {% endfor %}

    {% if errors | length > 0 %}
        {{ exceptions.raise_compiler_error(errors | join('\n')) }}
    {% endif %}
{% endmacro %}