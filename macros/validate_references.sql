{% macro validate_references() %}
    {{ log("Starting validation", info=True) }}

    {% set database_constraints = {
        'STAGING': ['CANON', 'MARTS'],
        'CANON': ['MARTS'],
        'MARTS': []
    } %}

    {{ log("Database constraints: " ~ database_constraints, info=True) }}

    {% set errors = [] %}

    {% for model in graph.nodes.values() %}
        {% if model.resource_type == 'model' %}
            {{ log("Checking model: " ~ model.unique_id, info=True) }}
            {% set model_database = model.database %}
            {% for reference in model.depends_on.nodes %}
                {% set referenced_model = graph.nodes[reference] %}
                {% set reference_database = referenced_model.database %}
                
                {{ log("Model " ~ model.unique_id ~ " references " ~ referenced_model.unique_id, info=True) }}
                
                {% if reference_database in database_constraints[model_database] %}
                    {% set error_message = "Model {{ model.unique_id }} references {{ reference_database }} which is not allowed for database {{ model_database }}" %}
                    {{ log(error_message, info=True) }}
                    {% do errors.append(error_message) %}
                {% endif %}
            {% endfor %}
        {% endif %}
    {% endfor %}

    {% if errors | length > 0 %}
        {{ exceptions.raise_compiler_error(errors | join('\n')) }}
    {% else %}
        {{ log("No validation errors found.", info=True) }}
    {% endif %}
{% endmacro %}

