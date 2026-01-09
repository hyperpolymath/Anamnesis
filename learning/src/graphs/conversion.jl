# SPDX-License-Identifier: AGPL-3.0-or-later
# RDF to MetaGraph Conversion

using Graphs
using MetaGraphs

"""
    rdf_to_metagraph(sparql_results::Vector{Dict}) -> MetaGraph

Convert SPARQL query results to a MetaGraph structure.

Expects results from a query like:
```sparql
SELECT ?s ?p ?o WHERE { ?s ?p ?o }
```

# Arguments
- `sparql_results`: Vector of Dict with "s", "p", "o" keys

# Returns
- MetaGraph with nodes as RDF resources and edges as predicates
"""
function rdf_to_metagraph(sparql_results::Vector{Dict})
    # Build node index
    nodes = Set{String}()
    for row in sparql_results
        push!(nodes, row["s"])
        if !startswith(string(row["o"]), "\"")  # Skip literals
            push!(nodes, string(row["o"]))
        end
    end

    node_list = collect(nodes)
    node_index = Dict(node => i for (i, node) in enumerate(node_list))

    # Create graph
    g = MetaGraph(length(node_list))

    # Set node properties
    for (i, uri) in enumerate(node_list)
        set_prop!(g, i, :uri, uri)
        set_prop!(g, i, :label, extract_local_name(uri))
    end

    # Add edges
    for row in sparql_results
        s_idx = node_index[row["s"]]
        o_value = string(row["o"])

        if haskey(node_index, o_value)
            o_idx = node_index[o_value]
            add_edge!(g, s_idx, o_idx)
            set_prop!(g, Edge(s_idx, o_idx), :predicate, row["p"])
        else
            # Object is a literal - store as node property
            prop_name = Symbol(extract_local_name(row["p"]))
            set_prop!(g, s_idx, prop_name, o_value)
        end
    end

    return g
end

"""
    extract_local_name(uri::String) -> String

Extract the local name (fragment or last path segment) from a URI.
"""
function extract_local_name(uri::String)::String
    if contains(uri, "#")
        return split(uri, "#")[end]
    elseif contains(uri, "/")
        return split(uri, "/")[end]
    else
        return uri
    end
end

"""
    metagraph_to_adjacency(g::MetaGraph) -> SparseMatrixCSC

Convert MetaGraph to sparse adjacency matrix.
"""
function metagraph_to_adjacency(g::MetaGraph)
    return adjacency_matrix(g)
end

"""
    conversation_graph_from_sparql(endpoint::String, conv_id::String) -> MetaGraph

Build a conversation graph from SPARQL queries.

# Arguments
- `endpoint`: SPARQL endpoint URL
- `conv_id`: Conversation ID to fetch
"""
function conversation_graph_from_sparql(endpoint::String, conv_id::String)
    query = """
    PREFIX anamnesis: <http://anamnesis.hyperpolymath.org/ns#>

    SELECT ?s ?p ?o
    WHERE {
        {
            ?s ?p ?o .
            FILTER(?s = anamnesis:conv:$conv_id)
        }
        UNION
        {
            anamnesis:conv:$conv_id anamnesis:contains ?msg .
            ?msg ?p ?o .
            BIND(?msg AS ?s)
        }
        UNION
        {
            anamnesis:conv:$conv_id anamnesis:discusses ?art .
            ?art ?p ?o .
            BIND(?art AS ?s)
        }
    }
    """

    results = execute_sparql(endpoint, query)
    return rdf_to_metagraph(results)
end

"""
    serialize_graph(g::MetaGraph) -> Dict

Serialize a MetaGraph to a JSON-compatible Dict.
"""
function serialize_graph(g::MetaGraph)::Dict
    nodes = []
    for v in vertices(g)
        node_props = props(g, v)
        push!(nodes, Dict(
            "id" => v,
            "uri" => get(node_props, :uri, ""),
            "label" => get(node_props, :label, ""),
            "properties" => Dict(
                string(k) => v for (k, v) in node_props
                if k ∉ [:uri, :label]
            )
        ))
    end

    edges_list = []
    for e in edges(g)
        edge_props = props(g, e)
        push!(edges_list, Dict(
            "source" => src(e),
            "target" => dst(e),
            "predicate" => get(edge_props, :predicate, "")
        ))
    end

    return Dict(
        "nodes" => nodes,
        "edges" => edges_list,
        "node_count" => nv(g),
        "edge_count" => ne(g)
    )
end

export rdf_to_metagraph, metagraph_to_adjacency, conversation_graph_from_sparql,
       serialize_graph, extract_local_name
