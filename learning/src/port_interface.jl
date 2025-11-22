# Port Interface for Elixir Communication
# Reads 4-byte length-prefixed JSON messages from stdin
# Responds with 4-byte length-prefixed JSON to stdout

using JSON
using .AnamnesisAnalytics

"""
Main port communication loop.

Reads requests from stdin, processes them, and writes responses to stdout.
Uses 4-byte length prefix for framing.
"""
function port_main()
    while true
        try
            # Read 4-byte length prefix (big-endian UInt32)
            len_bytes = read(stdin, 4)
            if length(len_bytes) < 4
                @error "Incomplete length prefix, exiting"
                break
            end

            len = ntoh(reinterpret(UInt32, len_bytes)[1])

            # Read JSON message
            msg_bytes = read(stdin, Int(len))
            if length(msg_bytes) < len
                @error "Incomplete message, exiting"
                break
            end

            request = JSON.parse(String(msg_bytes))

            # Process request
            result = process_request(request)

            # Send response
            response_json = JSON.json(result)
            response_bytes = Vector{UInt8}(response_json)
            response_len = UInt32(length(response_bytes))

            # Write length prefix (big-endian)
            write(stdout, hton(response_len))
            # Write message
            write(stdout, response_bytes)
            flush(stdout)

        catch e
            @error "Error in port loop" exception=(e, catch_backtrace())
            # Try to send error response
            try
                error_response = JSON.json(Dict(
                    "error" => string(e),
                    "backtrace" => sprint(showerror, e, catch_backtrace())
                ))
                error_bytes = Vector{UInt8}(error_response)
                write(stdout, hton(UInt32(length(error_bytes))))
                write(stdout, error_bytes)
                flush(stdout)
            catch
                # If even error reporting fails, just break
                break
            end
        end
    end
end

"""
Process a request from Elixir.

# Request format:
{
  "action": "generate_rdf" | "sparql_query" | "train_reservoir" | ...,
  ... (action-specific fields)
}

# Response format:
{
  "result": {...} | null,
  "error": String | null
}
"""
function process_request(request::Dict)::Dict
    action = request["action"]

    try
        if action == "generate_rdf"
            conversation = request["conversation"]
            triples = conversation_to_rdf(conversation)
            ntriples = serialize_ntriples(triples)
            return Dict("result" => Dict("rdf" => ntriples), "error" => nothing)

        elseif action == "sparql_query"
            endpoint = request["endpoint"]
            query = request["query"]
            results = execute_sparql(endpoint, query)
            return Dict("result" => Dict("results" => results), "error" => nothing)

        elseif action == "virtuoso_insert"
            endpoint = request["endpoint"]
            rdf = request["rdf"]
            virtuoso_insert(endpoint, rdf)
            return Dict("result" => Dict("status" => "ok"), "error" => nothing)

        elseif action == "rdf_to_metagraph"
            sparql_results = request["sparql_results"]
            graph = rdf_to_metagraph(sparql_results)
            # Serialize graph to JSON (simplified - full implementation would be more complex)
            graph_json = serialize_graph(graph)
            return Dict("result" => Dict("graph" => graph_json), "error" => nothing)

        else
            return Dict(
                "result" => nothing,
                "error" => "Unknown action: $action"
            )
        end

    catch e
        return Dict(
            "result" => nothing,
            "error" => sprint(showerror, e, catch_backtrace())
        )
    end
end

# Run port loop if this file is executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    port_main()
end
