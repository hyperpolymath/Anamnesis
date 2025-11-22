# RDF Triple Generation and Serialization

using ..Schema
using Dates
using UUIDs

struct Triple
    subject::String
    predicate::String
    object::String  # Can be URI or literal
end

"""
Generate RDF triples from a parsed conversation.

# Arguments
- `conversation::Dict`: Parsed conversation from OCaml/Elixir

# Returns
- `Vector{Triple}`: RDF triples ready for serialization
"""
function conversation_to_rdf(conversation::Dict)::Vector{Triple}
    triples = Triple[]

    # Conversation entity
    conv_id = conversation["id"]
    conv_uri = "anamnesis:conv:$conv_id"

    push!(triples, Triple(conv_uri, Schema.TYPE, Schema.CONVERSATION))

    # Timestamp
    if haskey(conversation, "timestamp")
        timestamp = conversation["timestamp"]
        # Convert Unix timestamp to ISO 8601
        dt = unix2datetime(timestamp)
        push!(triples, Triple(
            conv_uri,
            Schema.TIMESTAMP,
            "\"$(Dates.format(dt, "yyyy-mm-ddTHH:MM:SSZ"))\"^^xsd:dateTime"
        ))
    end

    # Platform
    if haskey(conversation, "platform") && !isnothing(conversation["platform"])
        push!(triples, Triple(
            conv_uri,
            ANAMNESIS[:platform],
            "\"$(conversation["platform"])\""
        ))
    end

    # Messages
    for msg in get(conversation, "messages", [])
        append!(triples, message_to_rdf(msg, conv_uri))
    end

    # Artifacts
    for artifact in get(conversation, "artifacts", [])
        append!(triples, artifact_to_rdf(artifact, conv_uri))
    end

    return triples
end

function message_to_rdf(msg::Dict, conv_uri::String)::Vector{Triple}
    triples = Triple[]

    msg_id = msg["id"]
    msg_uri = "anamnesis:msg:$msg_id"

    # Message type
    speaker_type = msg["speaker"]
    if speaker_type isa Dict && haskey(speaker_type, "LLM")
        push!(triples, Triple(msg_uri, Schema.TYPE, ANAMNESIS[:LLMMessage]))
        # Model info
        llm_info = speaker_type["LLM"]
        if haskey(llm_info, "model")
            speaker_uri = "anamnesis:speaker:$(llm_info["model"])"
            push!(triples, Triple(msg_uri, Schema.SPEAKER_PROP, speaker_uri))
            push!(triples, Triple(speaker_uri, Schema.TYPE, ANAMNESIS[:LLM]))
            push!(triples, Triple(
                speaker_uri,
                ANAMNESIS[:modelName],
                "\"$(llm_info["model"])\""
            ))
        end
    else
        push!(triples, Triple(msg_uri, Schema.TYPE, ANAMNESIS[:HumanMessage]))
        speaker_uri = "anamnesis:speaker:user"
        push!(triples, Triple(msg_uri, Schema.SPEAKER_PROP, speaker_uri))
    end

    # Part of conversation
    push!(triples, Triple(msg_uri, Schema.PART_OF, conv_uri))

    # Content
    if haskey(msg, "content")
        content = escape_string(msg["content"])
        push!(triples, Triple(msg_uri, Schema.CONTENT, "\"$content\""))
    end

    # Timestamp
    if haskey(msg, "timestamp")
        dt = unix2datetime(msg["timestamp"])
        push!(triples, Triple(
            msg_uri,
            Schema.TIMESTAMP,
            "\"$(Dates.format(dt, "yyyy-mm-ddTHH:MM:SSZ"))\"^^xsd:dateTime"
        ))
    end

    return triples
end

function artifact_to_rdf(artifact::Dict, conv_uri::String)::Vector{Triple}
    triples = Triple[]

    art_id = artifact["id"]
    art_uri = "anamnesis:artifact:$art_id"

    # Artifact type
    art_type = artifact["artifact_type"]
    if haskey(art_type, "Code")
        push!(triples, Triple(art_uri, Schema.TYPE, ANAMNESIS[:CodeArtifact]))
        lang = art_type["Code"]
        push!(triples, Triple(art_uri, ANAMNESIS[:language], "\"$lang\""))
    elseif art_type == "Documentation"
        push!(triples, Triple(art_uri, Schema.TYPE, ANAMNESIS[:DocumentationArtifact]))
    elseif art_type == "Configuration"
        push!(triples, Triple(art_uri, Schema.TYPE, ANAMNESIS[:ConfigurationArtifact]))
    else
        push!(triples, Triple(art_uri, Schema.TYPE, Schema.ARTIFACT))
    end

    # Name
    if haskey(artifact, "name") && !isnothing(artifact["name"])
        push!(triples, Triple(art_uri, ANAMNESIS[:artifactName], "\"$(artifact["name"])\""))
    end

    # Content
    if haskey(artifact, "content")
        content = escape_string(artifact["content"])
        push!(triples, Triple(art_uri, ANAMNESIS[:artifactContent], "\"$content\""))
    end

    # Created in
    if haskey(artifact, "created_in")
        msg_uri = "anamnesis:msg:$(artifact["created_in"])"
        push!(triples, Triple(art_uri, Schema.CREATED_IN, msg_uri))
    end

    # Current state
    if haskey(artifact, "current_state")
        state = artifact["current_state"]
        state_uri = if state == "Created"
            Schema.STATE_CREATED
        elseif state == "Modified"
            Schema.STATE_MODIFIED
        elseif state == "Removed"
            Schema.STATE_REMOVED
        elseif state == "Evaluated"
            Schema.STATE_EVALUATED
        end
        push!(triples, Triple(art_uri, Schema.STATE_PROP, state_uri))
    end

    # Discussion link
    push!(triples, Triple(conv_uri, Schema.DISCUSSES, art_uri))

    return triples
end

"""
Serialize triples to N-Triples format.
"""
function serialize_ntriples(triples::Vector{Triple})::String
    lines = String[]

    for triple in triples
        # Format: <subject> <predicate> <object> .
        subj = format_uri(triple.subject)
        pred = format_uri(triple.predicate)
        obj = format_value(triple.object)
        push!(lines, "$subj $pred $obj .")
    end

    return join(lines, "\n")
end

function format_uri(uri::String)::String
    if startswith(uri, "http://") || startswith(uri, "https://")
        return "<$uri>"
    elseif contains(uri, ":")
        # Prefixed name - expand to full URI
        # This is simplified - full implementation would maintain prefix map
        return "<http://anamnesis.hyperpolymath.org/ns#$(split(uri, ":")[2])>"
    else
        return "<$uri>"
    end
end

function format_value(value::String)::String
    if startswith(value, "\"")
        # Already a literal
        return value
    elseif startswith(value, "http://") || startswith(value, "https://")
        return "<$value>"
    elseif contains(value, ":")
        # Prefixed URI
        return format_uri(value)
    else
        # Treat as literal
        return "\"$value\""
    end
end
