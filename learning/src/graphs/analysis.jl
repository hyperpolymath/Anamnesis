# SPDX-License-Identifier: AGPL-3.0-or-later
# Graph Analysis Functions

using Graphs
using MetaGraphs
using Statistics
using LinearAlgebra

"""
    analyze_conversation_graph(g::MetaGraph) -> Dict

Compute various graph metrics for a conversation graph.

# Returns
Dict containing:
- node_count: Number of nodes
- edge_count: Number of edges
- density: Graph density
- components: Number of connected components
- diameter: Graph diameter (if connected)
- clustering: Average clustering coefficient
- centrality: Dict of centrality measures
"""
function analyze_conversation_graph(g::MetaGraph)::Dict
    result = Dict{String, Any}()

    # Basic metrics
    result["node_count"] = nv(g)
    result["edge_count"] = ne(g)
    result["density"] = density(g)

    # Components
    cc = connected_components(g)
    result["components"] = length(cc)
    result["largest_component_size"] = maximum(length.(cc))

    # Diameter (only if connected)
    if is_connected(g)
        result["diameter"] = diameter(g)
    else
        result["diameter"] = nothing
    end

    # Clustering coefficient
    result["clustering"] = global_clustering_coefficient(g)

    # Centrality measures
    result["centrality"] = Dict{String, Vector{Float64}}()
    if nv(g) > 0
        result["centrality"]["degree"] = Float64.(degree_centrality(g))
        result["centrality"]["betweenness"] = betweenness_centrality(g)
        result["centrality"]["closeness"] = closeness_centrality(g)
    end

    return result
end

"""
    find_central_nodes(g::MetaGraph; top_k::Int=10) -> Vector{Tuple{Int, Float64}}

Find the top-k most central nodes by betweenness centrality.
"""
function find_central_nodes(g::MetaGraph; top_k::Int=10)
    bc = betweenness_centrality(g)
    indices = sortperm(bc, rev=true)[1:min(top_k, length(bc))]
    return [(i, bc[i]) for i in indices]
end

"""
    find_bridges(g::MetaGraph) -> Vector{Edge}

Find bridge edges (edges whose removal disconnects the graph).
"""
function find_bridges(g::MetaGraph)::Vector{Edge}
    bridges = Edge[]
    for e in edges(g)
        # Create copy without this edge
        g_copy = copy(g)
        rem_edge!(g_copy, e)
        if !is_connected(g_copy) || length(connected_components(g_copy)) > length(connected_components(g))
            push!(bridges, e)
        end
    end
    return bridges
end

"""
    conversation_complexity_score(g::MetaGraph) -> Float64

Compute a complexity score for a conversation graph.

Higher scores indicate more complex conversations with:
- More cross-references
- More artifacts
- Higher interconnectivity
"""
function conversation_complexity_score(g::MetaGraph)::Float64
    if nv(g) == 0
        return 0.0
    end

    # Count different node types
    message_count = 0
    artifact_count = 0
    for v in vertices(g)
        uri = get_prop(g, v, :uri)
        if contains(uri, "msg:")
            message_count += 1
        elseif contains(uri, "artifact:")
            artifact_count += 1
        end
    end

    # Compute factors
    edge_factor = ne(g) / max(1, nv(g))
    artifact_factor = artifact_count / max(1, message_count)
    clustering_factor = global_clustering_coefficient(g)

    # Weighted combination
    score = 0.4 * edge_factor + 0.4 * artifact_factor + 0.2 * clustering_factor

    return score
end

"""
    find_conversation_clusters(g::MetaGraph) -> Vector{Vector{Int}}

Find clusters in a conversation graph using community detection.
"""
function find_conversation_clusters(g::MetaGraph)::Vector{Vector{Int}}
    # Use label propagation for community detection
    if nv(g) == 0
        return Vector{Int}[]
    end

    # Simple approach: use connected components as initial clusters
    return connected_components(g)
end

"""
    project_membership_graph(conversations::Vector{MetaGraph}, projects::Vector{String}) -> MetaGraph

Create a graph showing relationships between conversations and projects.
"""
function project_membership_graph(conversations::Vector{Tuple{String, MetaGraph}},
                                   projects::Vector{String})::MetaGraph
    # Create bipartite graph: conversations on one side, projects on other
    n_convs = length(conversations)
    n_projs = length(projects)
    total_nodes = n_convs + n_projs

    g = MetaGraph(total_nodes)

    # Set conversation nodes
    for (i, (conv_id, _)) in enumerate(conversations)
        set_prop!(g, i, :type, "conversation")
        set_prop!(g, i, :id, conv_id)
    end

    # Set project nodes
    for (i, proj) in enumerate(projects)
        node_idx = n_convs + i
        set_prop!(g, node_idx, :type, "project")
        set_prop!(g, node_idx, :id, proj)
    end

    return g
end

"""
    artifact_lifecycle_graph(artifacts::Vector{Dict}) -> MetaGraph

Create a graph representing artifact lifecycle transitions.
"""
function artifact_lifecycle_graph(artifacts::Vector{Dict})::MetaGraph
    # State nodes + artifact nodes
    states = ["Created", "Modified", "Removed", "Evaluated"]
    n_states = length(states)
    n_artifacts = length(artifacts)

    g = MetaGraph(n_states + n_artifacts)

    # State nodes
    for (i, state) in enumerate(states)
        set_prop!(g, i, :type, "state")
        set_prop!(g, i, :name, state)
    end

    # Artifact nodes and edges
    state_idx = Dict(s => i for (i, s) in enumerate(states))
    for (i, art) in enumerate(artifacts)
        node_idx = n_states + i
        set_prop!(g, node_idx, :type, "artifact")
        set_prop!(g, node_idx, :id, art["id"])

        # Edge to current state
        if haskey(art, "current_state") && haskey(state_idx, art["current_state"])
            s_idx = state_idx[art["current_state"]]
            add_edge!(g, node_idx, s_idx)
        end
    end

    return g
end

export analyze_conversation_graph, find_central_nodes, find_bridges,
       conversation_complexity_score, find_conversation_clusters,
       project_membership_graph, artifact_lifecycle_graph
