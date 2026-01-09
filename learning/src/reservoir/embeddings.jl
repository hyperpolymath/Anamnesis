# SPDX-License-Identifier: AGPL-3.0-or-later
# Graph and Conversation Embeddings

using Graphs
using MetaGraphs
using LinearAlgebra
using SparseArrays
using Statistics

"""
    graph_to_embedding(g::MetaGraph; dim::Int=64) -> Vector{Float64}

Generate a fixed-dimension embedding vector from a graph.

Uses spectral graph features combined with structural statistics.
"""
function graph_to_embedding(g::MetaGraph; dim::Int=64)::Vector{Float64}
    if nv(g) == 0
        return zeros(Float64, dim)
    end

    features = Float64[]

    # Structural features
    append!(features, structural_features(g))

    # Spectral features
    append!(features, spectral_features(g))

    # Degree distribution features
    append!(features, degree_distribution_features(g))

    # Pad or truncate to fixed dimension
    if length(features) < dim
        append!(features, zeros(dim - length(features)))
    elseif length(features) > dim
        features = features[1:dim]
    end

    return features
end

"""
    structural_features(g::AbstractGraph) -> Vector{Float64}

Extract basic structural features from a graph.
"""
function structural_features(g::AbstractGraph)::Vector{Float64}
    n = nv(g)
    m = ne(g)

    features = Float64[
        Float64(n),                           # Node count
        Float64(m),                           # Edge count
        m / max(1, n * (n - 1) / 2),         # Density
        Float64(length(connected_components(g))),  # Components
        is_connected(g) ? 1.0 : 0.0,         # Connected flag
    ]

    # Add clustering coefficient if possible
    push!(features, global_clustering_coefficient(g))

    return features
end

"""
    spectral_features(g::AbstractGraph; k::Int=10) -> Vector{Float64}

Extract spectral features from the graph Laplacian.
"""
function spectral_features(g::AbstractGraph; k::Int=10)::Vector{Float64}
    n = nv(g)
    if n == 0
        return zeros(Float64, k)
    end

    # Compute normalized Laplacian
    A = adjacency_matrix(g)
    D = Diagonal(vec(sum(A, dims=2)))

    # Handle disconnected nodes
    D_inv_sqrt = Diagonal([d > 0 ? 1/sqrt(d) : 0.0 for d in diag(D)])
    L_norm = I - D_inv_sqrt * A * D_inv_sqrt

    # Compute eigenvalues
    try
        eigenvalues = eigvals(Matrix(L_norm))
        real_eigenvalues = real.(eigenvalues)
        sorted_eigenvalues = sort(real_eigenvalues)

        # Return first k eigenvalues (or padded)
        if length(sorted_eigenvalues) >= k
            return sorted_eigenvalues[1:k]
        else
            return vcat(sorted_eigenvalues, zeros(k - length(sorted_eigenvalues)))
        end
    catch
        return zeros(Float64, k)
    end
end

"""
    degree_distribution_features(g::AbstractGraph) -> Vector{Float64}

Extract features from the degree distribution.
"""
function degree_distribution_features(g::AbstractGraph)::Vector{Float64}
    if nv(g) == 0
        return zeros(Float64, 5)
    end

    degrees = Float64.(degree(g))

    return Float64[
        mean(degrees),
        std(degrees),
        minimum(degrees),
        maximum(degrees),
        median(degrees)
    ]
end

"""
    message_sequence_embedding(messages::Vector{Dict}; dim::Int=32) -> Vector{Float64}

Create an embedding for a sequence of messages.
"""
function message_sequence_embedding(messages::Vector{Dict}; dim::Int=32)::Vector{Float64}
    if isempty(messages)
        return zeros(Float64, dim)
    end

    features = Float64[]

    # Sequence statistics
    push!(features, Float64(length(messages)))

    # Role distribution
    human_count = count(m -> get(m, "role", "") == "user", messages)
    llm_count = length(messages) - human_count
    push!(features, Float64(human_count))
    push!(features, Float64(llm_count))
    push!(features, human_count / max(1, length(messages)))

    # Content length statistics
    content_lengths = [
        Float64(length(get(m, "content", "")))
        for m in messages
    ]
    push!(features, mean(content_lengths))
    push!(features, std(content_lengths))
    push!(features, maximum(content_lengths))

    # Timestamp features
    timestamps = [get(m, "timestamp", 0.0) for m in messages]
    if length(timestamps) > 1
        intervals = diff(sort(timestamps))
        push!(features, mean(intervals))
        push!(features, std(intervals))
    else
        push!(features, 0.0)
        push!(features, 0.0)
    end

    # Pad to fixed dimension
    if length(features) < dim
        append!(features, zeros(dim - length(features)))
    elseif length(features) > dim
        features = features[1:dim]
    end

    return features
end

"""
    artifact_embedding(artifacts::Vector{Dict}; dim::Int=16) -> Vector{Float64}

Create an embedding for artifact collection.
"""
function artifact_embedding(artifacts::Vector{Dict}; dim::Int=16)::Vector{Float64}
    if isempty(artifacts)
        return zeros(Float64, dim)
    end

    features = Float64[]

    # Count by type
    type_counts = Dict{String, Int}()
    for art in artifacts
        art_type = get(art, "artifact_type", "unknown")
        if art_type isa Dict
            art_type = first(keys(art_type))
        end
        type_counts[string(art_type)] = get(type_counts, string(art_type), 0) + 1
    end

    push!(features, Float64(get(type_counts, "Code", 0)))
    push!(features, Float64(get(type_counts, "Documentation", 0)))
    push!(features, Float64(get(type_counts, "Configuration", 0)))
    push!(features, Float64(length(artifacts)))

    # State distribution
    state_counts = Dict{String, Int}()
    for art in artifacts
        state = get(art, "current_state", "Unknown")
        state_counts[string(state)] = get(state_counts, string(state), 0) + 1
    end

    push!(features, Float64(get(state_counts, "Created", 0)))
    push!(features, Float64(get(state_counts, "Modified", 0)))
    push!(features, Float64(get(state_counts, "Removed", 0)))
    push!(features, Float64(get(state_counts, "Evaluated", 0)))

    # Pad to fixed dimension
    if length(features) < dim
        append!(features, zeros(dim - length(features)))
    elseif length(features) > dim
        features = features[1:dim]
    end

    return features
end

"""
    conversation_embedding(conv::Dict; dim::Int=64) -> Vector{Float64}

Create a comprehensive embedding for a conversation.

Combines message sequence, artifact, and metadata embeddings.
"""
function conversation_embedding(conv::Dict; dim::Int=64)::Vector{Float64}
    # Split dimensions among components
    msg_dim = div(dim, 2)
    art_dim = div(dim, 4)
    meta_dim = dim - msg_dim - art_dim

    messages = get(conv, "messages", Dict[])
    artifacts = get(conv, "artifacts", Dict[])

    msg_emb = message_sequence_embedding(messages; dim=msg_dim)
    art_emb = artifact_embedding(artifacts; dim=art_dim)

    # Metadata features
    meta_features = Float64[]
    push!(meta_features, get(conv, "timestamp", 0.0) / 1e10)

    platform = get(conv, "platform", "unknown")
    push!(meta_features, platform == "claude" ? 1.0 : 0.0)
    push!(meta_features, platform == "chatgpt" ? 1.0 : 0.0)
    push!(meta_features, platform == "mistral" ? 1.0 : 0.0)

    if length(meta_features) < meta_dim
        append!(meta_features, zeros(meta_dim - length(meta_features)))
    end

    return vcat(msg_emb, art_emb, meta_features[1:meta_dim])
end

export graph_to_embedding, structural_features, spectral_features,
       degree_distribution_features, message_sequence_embedding,
       artifact_embedding, conversation_embedding
