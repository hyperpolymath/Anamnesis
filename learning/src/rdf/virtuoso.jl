# SPDX-License-Identifier: AGPL-3.0-or-later
# Virtuoso RDF Store Client

using HTTP
using URIs

"""
    virtuoso_insert(endpoint::String, rdf::String; graph::Union{String, Nothing}=nothing)

Insert RDF triples into Virtuoso triplestore.

# Arguments
- `endpoint`: The Virtuoso SPARQL endpoint URL
- `rdf`: RDF content in N-Triples format
- `graph`: Optional named graph URI

# Example
```julia
virtuoso_insert("http://localhost:8890/sparql", ntriples_content,
                graph="http://anamnesis.hyperpolymath.org/graphs/conversations")
```
"""
function virtuoso_insert(endpoint::String, rdf::String; graph::Union{String, Nothing}=nothing)
    # Virtuoso uses SPARQL Graph Store Protocol for uploads
    graph_store_url = replace(endpoint, "/sparql" => "/sparql-graph-crud-auth")

    params = Dict{String, String}()
    if !isnothing(graph)
        params["graph"] = graph
    else
        params["default"] = ""
    end

    url = string(graph_store_url, "?", URIs.escapeuri(params))

    headers = [
        "Content-Type" => "application/n-triples"
    ]

    try
        response = HTTP.post(url, headers, rdf)

        if response.status in [200, 201, 204]
            return nothing
        else
            error("Virtuoso insert failed with status $(response.status)")
        end
    catch e
        if e isa HTTP.ExceptionRequest.StatusError
            error("Virtuoso insert error: $(e.status) - $(String(e.response.body))")
        else
            rethrow(e)
        end
    end
end

"""
    virtuoso_update(endpoint::String, update_query::String)

Execute a SPARQL UPDATE query against Virtuoso.

# Arguments
- `endpoint`: The Virtuoso SPARQL endpoint URL
- `update_query`: SPARQL UPDATE query (INSERT DATA, DELETE, etc.)

# Example
```julia
virtuoso_update("http://localhost:8890/sparql", \"\"\"
    PREFIX anamnesis: <http://anamnesis.hyperpolymath.org/ns#>
    INSERT DATA {
        GRAPH <http://anamnesis.hyperpolymath.org/graphs/test> {
            anamnesis:conv:123 a anamnesis:Conversation .
        }
    }
\"\"\")
```
"""
function virtuoso_update(endpoint::String, update_query::String)
    headers = [
        "Content-Type" => "application/sparql-update"
    ]

    try
        response = HTTP.post(endpoint, headers, update_query)

        if response.status in [200, 204]
            return nothing
        else
            error("Virtuoso update failed with status $(response.status)")
        end
    catch e
        if e isa HTTP.ExceptionRequest.StatusError
            error("Virtuoso update error: $(e.status)")
        else
            rethrow(e)
        end
    end
end

"""
    virtuoso_drop_graph(endpoint::String, graph::String; silent::Bool=true)

Drop a named graph from Virtuoso.

# Arguments
- `endpoint`: The Virtuoso SPARQL endpoint URL
- `graph`: The graph URI to drop
- `silent`: If true, don't error if graph doesn't exist
"""
function virtuoso_drop_graph(endpoint::String, graph::String; silent::Bool=true)
    silent_keyword = silent ? "SILENT" : ""
    query = "DROP $silent_keyword GRAPH <$graph>"
    virtuoso_update(endpoint, query)
end

"""
    virtuoso_clear_graph(endpoint::String, graph::String)

Clear all triples from a named graph without dropping it.
"""
function virtuoso_clear_graph(endpoint::String, graph::String)
    query = "CLEAR GRAPH <$graph>"
    virtuoso_update(endpoint, query)
end

"""
    virtuoso_list_graphs(endpoint::String) -> Vector{String}

List all named graphs in the Virtuoso store.
"""
function virtuoso_list_graphs(endpoint::String)::Vector{String}
    query = "SELECT DISTINCT ?g WHERE { GRAPH ?g { ?s ?p ?o } }"
    results = execute_sparql(endpoint, query)
    return [row["g"] for row in results]
end

"""
    virtuoso_graph_count(endpoint::String, graph::String) -> Int

Count the number of triples in a named graph.
"""
function virtuoso_graph_count(endpoint::String, graph::String)::Int
    query = "SELECT (COUNT(*) AS ?count) WHERE { GRAPH <$graph> { ?s ?p ?o } }"
    results = execute_sparql(endpoint, query)
    if isempty(results)
        return 0
    end
    return results[1]["count"]
end

"""
    virtuoso_health_check(endpoint::String) -> Bool

Check if Virtuoso is responding.
"""
function virtuoso_health_check(endpoint::String)::Bool
    try
        query = "SELECT 1 WHERE { }"
        execute_sparql(endpoint, query)
        return true
    catch
        return false
    end
end

export virtuoso_insert, virtuoso_update, virtuoso_drop_graph,
       virtuoso_clear_graph, virtuoso_list_graphs, virtuoso_graph_count,
       virtuoso_health_check
