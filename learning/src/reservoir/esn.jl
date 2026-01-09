# SPDX-License-Identifier: AGPL-3.0-or-later
# Echo State Network for Conversation Analysis

using ReservoirComputing
using SparseArrays
using LinearAlgebra
using Random

"""
    ConversationESN

Echo State Network configuration for conversation prediction.
"""
struct ConversationESN
    reservoir_size::Int
    spectral_radius::Float64
    sparsity::Float64
    input_scaling::Float64
    regularization::Float64
end

"""
    default_esn_config() -> ConversationESN

Create default ESN configuration for conversation analysis.
"""
function default_esn_config()::ConversationESN
    return ConversationESN(
        100,    # reservoir_size
        0.9,    # spectral_radius
        0.1,    # sparsity
        1.0,    # input_scaling
        1e-6    # regularization
    )
end

"""
    create_reservoir(config::ConversationESN, input_dim::Int) -> ESN

Create an Echo State Network with the given configuration.

# Arguments
- `config`: ConversationESN configuration
- `input_dim`: Dimension of input vectors
"""
function create_reservoir(config::ConversationESN, input_dim::Int)
    reservoir = RandSparseReservoir(
        config.reservoir_size;
        radius=config.spectral_radius,
        sparsity=config.sparsity
    )

    input_layer = WeightedLayer(
        scaling=config.input_scaling
    )

    readout = StandardRidge(config.regularization)

    return ESN(
        reservoir;
        input_layer=input_layer,
        reservoir_driver=RNN(),
        nla_type=NLADefault(),
        states_type=StandardStates()
    )
end

"""
    train_conversation_predictor(embeddings::Matrix{Float64},
                                  targets::Matrix{Float64};
                                  config::ConversationESN=default_esn_config())

Train an ESN to predict conversation properties.

# Arguments
- `embeddings`: Input embedding matrix (features x timesteps)
- `targets`: Target values matrix
- `config`: ESN configuration

# Returns
Tuple of (trained ESN, output weights)
"""
function train_conversation_predictor(embeddings::Matrix{Float64},
                                       targets::Matrix{Float64};
                                       config::ConversationESN=default_esn_config())
    input_dim = size(embeddings, 1)
    esn = create_reservoir(config, input_dim)

    # Train the reservoir
    output_layer = train(esn, embeddings, targets;
                         washout=10,
                         ridge_regression=config.regularization)

    return (esn, output_layer)
end

"""
    predict_conversation(esn, output_layer, embedding::Vector{Float64})

Use trained ESN to predict conversation properties.
"""
function predict_conversation(esn, output_layer, embedding::Matrix{Float64})
    return esn(Predictive(), embedding, output_layer)
end

"""
    create_knowledge_augmented_reservoir(rules::Vector{Dict},
                                         input_dim::Int;
                                         reservoir_size::Int=100)

Create a reservoir with knowledge-augmented structure.

# Arguments
- `rules`: Vector of logic rules as Dict with :antecedent and :consequent
- `input_dim`: Input dimension
- `reservoir_size`: Size of random reservoir portion
"""
function create_knowledge_augmented_reservoir(rules::Vector{Dict},
                                               input_dim::Int;
                                               reservoir_size::Int=100)
    n_rules = length(rules)
    total_size = n_rules + reservoir_size

    # Initialize weight matrix
    W = spzeros(Float64, total_size, total_size)

    # Rule-based connections (first n_rules nodes)
    for (i, rule) in enumerate(rules)
        # Encode rule structure
        # Each rule creates a structured connection pattern
        if haskey(rule, :antecedent_indices)
            for j in rule[:antecedent_indices]
                if j <= total_size
                    W[i, j] = rule[:weight]
                end
            end
        end
    end

    # Random reservoir portion
    random_portion = sprandn(reservoir_size, reservoir_size, 0.1)

    # Scale random portion to desired spectral radius
    eigenvalues = eigvals(Matrix(random_portion))
    max_eigenvalue = maximum(abs.(eigenvalues))
    if max_eigenvalue > 0
        random_portion .*= (0.9 / max_eigenvalue)
    end

    # Insert into weight matrix
    W[n_rules+1:end, n_rules+1:end] = random_portion

    # Create custom reservoir
    return CustomReservoir(W)
end

"""
    CustomReservoir

A reservoir with custom weight matrix.
"""
struct CustomReservoir
    W::SparseMatrixCSC{Float64, Int}
end

"""
    conversation_sequence_to_timeseries(conversations::Vector{Dict}) -> Matrix{Float64}

Convert a sequence of conversations to time series for ESN training.

# Arguments
- `conversations`: Vector of parsed conversation Dicts

# Returns
Matrix where each column is a feature vector for one timestep
"""
function conversation_sequence_to_timeseries(conversations::Vector{Dict})::Matrix{Float64}
    features = []

    for conv in conversations
        feature_vec = extract_conversation_features(conv)
        push!(features, feature_vec)
    end

    # Stack as columns
    return hcat(features...)
end

"""
    extract_conversation_features(conv::Dict) -> Vector{Float64}

Extract numerical features from a conversation for ESN input.
"""
function extract_conversation_features(conv::Dict)::Vector{Float64}
    features = Float64[]

    # Message count
    push!(features, Float64(length(get(conv, "messages", []))))

    # Artifact count
    push!(features, Float64(length(get(conv, "artifacts", []))))

    # Timestamp (normalized)
    timestamp = get(conv, "timestamp", 0.0)
    push!(features, timestamp / 1e10)  # Normalize

    # Platform encoding (one-hot style)
    platform = get(conv, "platform", "unknown")
    push!(features, platform == "claude" ? 1.0 : 0.0)
    push!(features, platform == "chatgpt" ? 1.0 : 0.0)
    push!(features, platform == "mistral" ? 1.0 : 0.0)

    # State distribution
    artifacts = get(conv, "artifacts", [])
    states = ["Created", "Modified", "Removed", "Evaluated"]
    for state in states
        count = count(a -> get(a, "current_state", "") == state, artifacts)
        push!(features, Float64(count))
    end

    return features
end

export ConversationESN, default_esn_config, create_reservoir,
       train_conversation_predictor, predict_conversation,
       create_knowledge_augmented_reservoir, CustomReservoir,
       conversation_sequence_to_timeseries, extract_conversation_features
