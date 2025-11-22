# Learning Component (Julia)

RDF manipulation, graph processing, reservoir computing, and knowledge-augmented neural networks for Anamnesis analytics.

## Purpose

- Generate RDF triples from parsed conversations
- Execute SPARQL queries against Virtuoso
- Convert RDF graphs to MetaGraph structures
- Train reservoir computing models for conversation analysis
- Implement KBANN (Knowledge-Based Artificial Neural Networks)
- Predict conversation patterns and categorization

## Technology Stack

- **Julia** 1.10+
- **Serd.jl** - RDF serialization (N-Triples, Turtle)
- **HTTP.jl** - SPARQL endpoint communication
- **ReservoirComputing.jl** - Echo State Networks
- **Flux.jl** - Deep learning framework (for KBANN)
- **GraphNeuralNetworks.jl** - Graph embeddings
- **Graphs.jl + MetaGraphs.jl** - Graph processing
- **CUDA.jl** - GPU acceleration (optional)

## Directory Structure

```
learning/
├── src/
│   ├── AnamnesisAnalytics.jl   # Main module
│   ├── rdf/
│   │   ├── serialization.jl    # Serd.jl RDF generation
│   │   ├── sparql.jl           # SPARQL query execution
│   │   ├── schema.jl           # Anamnesis ontology constants
│   │   └── virtuoso.jl         # Virtuoso client
│   ├── reservoir/
│   │   ├── esn.jl              # Echo State Networks
│   │   ├── embeddings.jl       # Graph→time series conversion
│   │   └── kbann.jl            # Knowledge-augmented networks
│   ├── graphs/
│   │   ├── conversion.jl       # RDF → MetaGraph
│   │   ├── analysis.jl         # Graph algorithms
│   │   └── features.jl         # Feature extraction
│   └── port_interface.jl       # Elixir port communication
├── test/
│   ├── rdf_tests.jl
│   ├── reservoir_tests.jl
│   ├── graph_tests.jl
│   └── fixtures/
│       └── sample_conversations.json
├── Project.toml
├── Manifest.toml
└── README.md                   # This file
```

## Key Concepts

### RDF Triple Generation

Convert parsed conversations to RDF:

```julia
struct Conversation
    id::String
    platform::Union{String, Nothing}
    timestamp::Float64
    messages::Vector{Message}
    artifacts::Vector{Artifact}
    metadata::Dict{String, String}
end

function conversation_to_rdf(conv::Conversation)
    triples = Triple[]

    # Conversation entity
    conv_uri = URI("anamnesis:conv:$(conv.id)")
    push!(triples, Triple(conv_uri, RDF.type, ANAMNESIS.Conversation))
    push!(triples, Triple(conv_uri, ANAMNESIS.timestamp,
                         Literal(conv.timestamp, XSD.dateTime)))

    # Messages
    for msg in conv.messages
        msg_uri = URI("anamnesis:msg:$(msg.id)")
        push!(triples, Triple(msg_uri, RDF.type, ANAMNESIS.Message))
        push!(triples, Triple(msg_uri, ANAMNESIS.partOf, conv_uri))
        push!(triples, Triple(msg_uri, ANAMNESIS.content, Literal(msg.content)))
    end

    # Artifacts with lifecycle
    for artifact in conv.artifacts
        artifact_uri = URI("anamnesis:artifact:$(artifact.id)")
        push!(triples, Triple(artifact_uri, RDF.type, ANAMNESIS.Artifact))
        push!(triples, Triple(artifact_uri, ANAMNESIS.state,
                            ANAMNESIS[Symbol(artifact.current_state)]))
    end

    return triples
end
```

### SPARQL Queries

```julia
using HTTP, JSON

function sparql_query(endpoint::String, query::String)
    response = HTTP.post(
        endpoint,
        ["Content-Type" => "application/sparql-query",
         "Accept" => "application/sparql-results+json"],
        query;
        redirect_method="POST"
    )

    results = JSON.parse(String(response.body))
    return parse_sparql_results(results)
end

function parse_sparql_results(json)
    bindings = json["results"]["bindings"]
    return [Dict(k => v["value"] for (k, v) in row) for row in bindings]
end
```

### Reservoir Computing

```julia
using ReservoirComputing

function train_conversation_predictor(conversations)
    # Convert conversations to time series
    embeddings = map(conversation_to_embedding, conversations)

    # Create reservoir
    reservoir = RandSparseReservoir(
        100,                    # Reservoir size
        radius=1.2,            # Spectral radius
        sparsity=0.1           # Connection sparsity
    )

    # Create ESN
    esn = ESN(
        reservoir,
        input_layer = WeightedLayer(),
        readout = StandardRidge(1e-6)
    )

    # Train
    output_layer = train(esn, embeddings, targets)

    return esn, output_layer
end
```

### KBANN (Knowledge-Augmented Networks)

```julia
using Flux

function create_kbann(rules::Vector{LogicRule}, input_dim::Int)
    # Encode symbolic rules as network structure
    rule_neurons = map(rule_to_neuron, rules)

    # Structured sub-network (from rules)
    structured = Chain(
        Dense(input_dim => length(rule_neurons), rule_to_weights.(rules)),
        σ
    )

    # Random reservoir sub-network
    reservoir_size = 100
    reservoir = Chain(
        Dense(input_dim => reservoir_size, randn),
        tanh
    )

    # Merge structured + random
    combined = Parallel(
        vcat,
        structured,
        reservoir
    )

    # Readout layer
    readout = Dense(length(rule_neurons) + reservoir_size => output_dim)

    return Chain(combined, readout)
end
```

## Building

### Install Julia

```bash
# Using juliaup (recommended)
curl -fsSL https://install.julialang.org | sh

# Set version
juliaup add 1.10
juliaup default 1.10
```

### Install Dependencies

```julia
# From Julia REPL
using Pkg

Pkg.activate(".")
Pkg.instantiate()

# Or from shell
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

### Package List

Add to `Project.toml`:

```toml
[deps]
Serd = "...uuid..."
HTTP = "cd3eb016-35fb-5094-929b-558a96fad6f3"
JSON = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
Graphs = "86223c79-3864-5bf0-83f7-82e725a168b6"
MetaGraphs = "626554b9-1ddb-594c-aa3c-2596fe9399a5"
ReservoirComputing = "...uuid..."
Flux = "587475ba-b771-5e3f-ad9e-33799f191a9c"
GraphNeuralNetworks = "...uuid..."
CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
```

### Build

```bash
julia --project=. -e 'using Pkg; Pkg.build()'
```

## Usage

### Generate RDF from Conversation

```julia
using AnamnesisAnalytics

# Parse conversation (from Elixir)
conv = parse_conversation_json(raw_json)

# Generate RDF triples
triples = conversation_to_rdf(conv)

# Serialize to N-Triples
ntriples = serialize_ntriples(triples)

# Upload to Virtuoso
virtuoso_insert("http://localhost:8890/sparql", ntriples)
```

### Query Virtuoso

```julia
# SPARQL query
query = """
PREFIX anamnesis: <http://anamnesis.hyperpolymath.org/ns#>
SELECT ?conv ?timestamp
WHERE {
    ?conv a anamnesis:Conversation ;
          anamnesis:timestamp ?timestamp .
}
ORDER BY DESC(?timestamp)
LIMIT 10
"""

results = sparql_query("http://localhost:8890/sparql", query)
for row in results
    println("Conversation: $(row["conv"]), Time: $(row["timestamp"])")
end
```

### Train Reservoir Model

```julia
# Fetch conversations from Virtuoso
conversations = fetch_conversations_from_sparql()

# Convert to MetaGraphs
graphs = map(rdf_to_metagraph, conversations)

# Generate embeddings
embeddings = map(graph_to_embedding, graphs)

# Train ESN
esn, output_layer = train_conversation_predictor(embeddings)

# Predict
new_conv_embedding = graph_to_embedding(new_conv_graph)
prediction = esn(Predictive(), new_conv_embedding, output_layer)
```

### Port Interface (Elixir Communication)

```julia
# port_interface.jl
using JSON

function main()
    while true
        # Read 4-byte length prefix
        len_bytes = read(stdin, 4)
        len = reinterpret(UInt32, len_bytes)[1]

        # Read JSON request
        request_json = String(read(stdin, len))
        request = JSON.parse(request_json)

        # Process request
        result = process_request(request)

        # Send response
        response_json = JSON.json(result)
        response_bytes = codeunits(response_json)
        write(stdout, reinterpret(UInt8, [UInt32(length(response_bytes))]))
        write(stdout, response_bytes)
        flush(stdout)
    end
end

function process_request(request)
    action = request["action"]

    if action == "generate_rdf"
        conv = parse_conversation(request["conversation"])
        triples = conversation_to_rdf(conv)
        return Dict("rdf" => serialize_ntriples(triples))

    elseif action == "sparql_query"
        results = sparql_query(request["endpoint"], request["query"])
        return Dict("results" => results)

    elseif action == "train_reservoir"
        # Train model on provided data
        model = train_reservoir_model(request["data"])
        return Dict("model_id" => save_model(model))

    else
        return Dict("error" => "unknown action: $action")
    end
end

# Run port loop
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
```

## Testing

### Unit Tests

```julia
# test/rdf_tests.jl
using Test
using AnamnesisAnalytics

@testset "RDF Generation" begin
    conv = Conversation(
        "test-123",
        "claude",
        1732291200.0,
        [Message("msg-1", "user", "Hello", 1732291200.0)],
        [],
        Dict()
    )

    triples = conversation_to_rdf(conv)

    @test length(triples) >= 3
    @test any(t -> t.predicate == RDF.type && t.object == ANAMNESIS.Conversation, triples)
end

@testset "SPARQL Queries" begin
    # Assumes Virtuoso running on localhost:8890
    query = "SELECT ?s WHERE { ?s a <http://example.org/Test> } LIMIT 1"
    results = sparql_query("http://localhost:8890/sparql", query)
    @test isa(results, Vector)
end
```

### Run Tests

```bash
julia --project=. test/runtests.jl
```

## Performance Optimizations

### Type Stability

```julia
# Bad: type-unstable
function process(x)
    if rand() > 0.5
        return 1          # Int
    else
        return 1.0        # Float64
    end
end

# Good: type-stable
function process(x)::Float64
    if rand() > 0.5
        return 1.0
    else
        return 1.0
    end
end
```

### GPU Acceleration

```julia
using CUDA

# Move to GPU if available
if CUDA.functional()
    reservoir_matrix = CuArray(reservoir_matrix)
    input_data = CuArray(input_data)
end
```

### Sparse Matrices

```julia
using SparseArrays

# For large, sparse graphs
adjacency = sparse(row_indices, col_indices, values, n, n)
```

### Batch Processing

```julia
# Process multiple conversations in batch
function batch_generate_rdf(conversations::Vector{Conversation})
    triples_list = map(conversation_to_rdf, conversations)
    all_triples = reduce(vcat, triples_list)
    return serialize_ntriples(all_triples)
end
```

## Monitoring

### Logging

```julia
using Logging

@info "Generating RDF for conversation" conv_id=conv.id num_messages=length(conv.messages)
@warn "Large conversation detected" conv_id=conv.id size=length(conv.messages)
@error "Failed to serialize RDF" exception=e
```

### Profiling

```julia
using Profile

@profile for i in 1:1000
    conversation_to_rdf(sample_conv)
end

Profile.print()
```

### Benchmarking

```julia
using BenchmarkTools

@benchmark conversation_to_rdf($sample_conv)
```

## Advanced Features

### Graph Embeddings

```julia
using GraphNeuralNetworks

function graph_to_embedding(metagraph::MetaGraph)
    # Convert to GNN-compatible format
    graph = to_gnn_graph(metagraph)

    # Define GNN
    gnn = GNNChain(
        GCNConv(node_features => 64),
        relu,
        GCNConv(64 => 32),
        GlobalPool(mean)
    )

    # Generate embedding
    embedding = gnn(graph)
    return embedding
end
```

### Knowledge-Augmented ESN

```julia
function knowledge_augmented_esn(rules::Vector{LogicRule}, input_dim::Int)
    # Rule-based structured connections
    rule_weights = stack(rule_to_weights.(rules))

    # Random reservoir
    random_weights = randn(100, input_dim) * 0.1

    # Combine
    combined_weights = vcat(rule_weights, random_weights)

    # Create reservoir with combined initialization
    reservoir = CustomReservoir(combined_weights, radius=1.2)

    return ESN(reservoir, readout=StandardRidge(1e-6))
end
```

## Deployment

### As Port Process

```bash
# Run Julia port
julia --project=/app learning/src/port_interface.jl
```

### As Service

```julia
# service.jl
using HTTP

HTTP.serve(8080) do request
    if request.method == "POST" && request.target == "/generate_rdf"
        body = JSON.parse(String(request.body))
        conv = parse_conversation(body["conversation"])
        triples = conversation_to_rdf(conv)
        return HTTP.Response(200, JSON.json(Dict("rdf" => serialize_ntriples(triples))))
    end
end
```

## Troubleshooting

### Package Installation Fails

```bash
# Clear package cache
rm -rf ~/.julia/packages
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

### GPU Not Detected

```julia
using CUDA
CUDA.functional()  # Should return true if GPU available

# Check CUDA version
CUDA.versioninfo()
```

### Memory Issues

```julia
# Use streaming for large datasets
function stream_process(file_path)
    open(file_path) do io
        for line in eachline(io)
            process_line(line)
            GC.gc()  # Force garbage collection
        end
    end
end
```

## References

- [Julia Documentation](https://docs.julialang.org/)
- [Serd.jl](https://github.com/JuliaGraphs/Serd.jl)
- [ReservoirComputing.jl Paper](https://jmlr.org/papers/v23/21-0945.html)
- [GraphNeuralNetworks.jl](https://arxiv.org/abs/2412.06354)
- Research: `/docs/research/julia-rdf-ecosystem.adoc`
- Research: `/docs/research/julia-reservoir-computing.adoc`
- Architecture: `/docs/architecture/system-architecture.adoc`

## Next Steps

1. Implement RDF serialization module
2. Create SPARQL client
3. Build RDF→MetaGraph converter
4. Implement basic ESN training
5. Create KBANN prototype
6. Integrate with Elixir via port
7. Test on proving-ground data
