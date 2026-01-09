# SPDX-License-Identifier: AGPL-3.0-or-later
# SPARQL Query Execution Module

using HTTP
using JSON

"""
    execute_sparql(endpoint::String, query::String) -> Vector{Dict}

Execute a SPARQL query against a SPARQL endpoint.

# Arguments
- `endpoint`: The SPARQL endpoint URL (e.g., "http://localhost:8890/sparql")
- `query`: The SPARQL query string

# Returns
- Vector of Dict containing query results (bindings)

# Example
```julia
results = execute_sparql("http://localhost:8890/sparql", \"\"\"
    PREFIX anamnesis: <http://anamnesis.hyperpolymath.org/ns#>
    SELECT ?conv ?timestamp
    WHERE {
        ?conv a anamnesis:Conversation ;
              anamnesis:timestamp ?timestamp .
    }
    LIMIT 10
\"\"\")
```
"""
function execute_sparql(endpoint::String, query::String)::Vector{Dict}
    headers = [
        "Content-Type" => "application/sparql-query",
        "Accept" => "application/sparql-results+json"
    ]

    try
        response = HTTP.post(
            endpoint,
            headers,
            query;
            redirect_method="POST",
            retry=true,
            retries=3
        )

        if response.status != 200
            error("SPARQL query failed with status $(response.status)")
        end

        results = JSON.parse(String(response.body))
        return parse_sparql_results(results)

    catch e
        if e isa HTTP.ExceptionRequest.StatusError
            error("SPARQL endpoint returned error: $(e.status)")
        else
            rethrow(e)
        end
    end
end

"""
    parse_sparql_results(json::Dict) -> Vector{Dict}

Parse SPARQL JSON results format into a vector of binding dictionaries.
"""
function parse_sparql_results(json::Dict)::Vector{Dict}
    if !haskey(json, "results") || !haskey(json["results"], "bindings")
        return Dict[]
    end

    bindings = json["results"]["bindings"]
    return [
        Dict(k => extract_value(v) for (k, v) in row)
        for row in bindings
    ]
end

"""
    extract_value(binding::Dict) -> Any

Extract the value from a SPARQL binding, handling different types.
"""
function extract_value(binding::Dict)
    value = binding["value"]
    binding_type = get(binding, "type", "literal")

    if binding_type == "uri"
        return value
    elseif binding_type == "literal"
        datatype = get(binding, "datatype", nothing)
        if datatype == "http://www.w3.org/2001/XMLSchema#integer"
            return parse(Int, value)
        elseif datatype == "http://www.w3.org/2001/XMLSchema#float" ||
               datatype == "http://www.w3.org/2001/XMLSchema#double"
            return parse(Float64, value)
        elseif datatype == "http://www.w3.org/2001/XMLSchema#boolean"
            return lowercase(value) == "true"
        elseif datatype == "http://www.w3.org/2001/XMLSchema#dateTime"
            return value  # Keep as string for now, could parse to DateTime
        else
            return value
        end
    elseif binding_type == "bnode"
        return "_:$(value)"
    else
        return value
    end
end

"""
    sparql_ask(endpoint::String, query::String) -> Bool

Execute a SPARQL ASK query and return boolean result.
"""
function sparql_ask(endpoint::String, query::String)::Bool
    headers = [
        "Content-Type" => "application/sparql-query",
        "Accept" => "application/sparql-results+json"
    ]

    response = HTTP.post(endpoint, headers, query)
    results = JSON.parse(String(response.body))
    return get(results, "boolean", false)
end

"""
    sparql_construct(endpoint::String, query::String) -> String

Execute a SPARQL CONSTRUCT query and return RDF in N-Triples format.
"""
function sparql_construct(endpoint::String, query::String)::String
    headers = [
        "Content-Type" => "application/sparql-query",
        "Accept" => "application/n-triples"
    ]

    response = HTTP.post(endpoint, headers, query)
    return String(response.body)
end

export execute_sparql, sparql_ask, sparql_construct, parse_sparql_results
