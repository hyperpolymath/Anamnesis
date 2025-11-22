module AnamnesisAnalytics

using Serd
using HTTP
using JSON
using Graphs
using MetaGraphs
using ReservoirComputing
using Flux
using SparseArrays
using LinearAlgebra

# Include submodules
include("rdf/schema.jl")
include("rdf/serialization.jl")
include("rdf/sparql.jl")
include("rdf/virtuoso.jl")
include("graphs/conversion.jl")
include("graphs/analysis.jl")
include("reservoir/esn.jl")
include("reservoir/embeddings.jl")
include("port_interface.jl")

# Export main functions
export conversation_to_rdf
export execute_sparql
export virtuoso_insert
export rdf_to_metagraph
export train_conversation_predictor

end # module
