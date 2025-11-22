using Test
using AnamnesisAnalytics
using AnamnesisAnalytics.RDF
using AnamnesisAnalytics.Schema

@testset "AnamnesisAnalytics Tests" begin
    @testset "RDF Schema Constants" begin
        @test Schema.BASE == "http://anamnesis.ai/ontology/"
        @test Schema.TYPE == "rdf:type"
        @test Schema.CONVERSATION == "anamnesis:Conversation"
        @test Schema.MESSAGE == "anamnesis:Message"
        @test Schema.ARTIFACT == "anamnesis:Artifact"
    end

    @testset "RDF Triple Structure" begin
        triple = RDF.Triple(
            "anamnesis:conv:test-001",
            "rdf:type",
            "anamnesis:Conversation"
        )

        @test triple.subject == "anamnesis:conv:test-001"
        @test triple.predicate == "rdf:type"
        @test triple.object == "anamnesis:Conversation"
    end

    @testset "Conversation to RDF Conversion" begin
        sample_conversation = Dict(
            "id" => "test-conv-001",
            "platform" => "Claude",
            "timestamp" => 1732272000.0,
            "messages" => [
                Dict(
                    "id" => "msg-1",
                    "role" => "user",
                    "content" => "Hello, Claude",
                    "timestamp" => 1732272000.0
                ),
                Dict(
                    "id" => "msg-2",
                    "role" => "assistant",
                    "content" => "Hello! How can I help?",
                    "timestamp" => 1732272010.0
                )
            ]
        )

        triples = RDF.conversation_to_rdf(sample_conversation)

        @test length(triples) > 0
        @test any(t -> t.predicate == "rdf:type" && t.object == "anamnesis:Conversation", triples)

        # Should have triples for messages
        message_triples = filter(t -> contains(t.subject, "msg:"), triples)
        @test length(message_triples) > 0
    end

    @testset "Message to RDF Conversion" begin
        message = Dict(
            "id" => "msg-test-001",
            "role" => "user",
            "content" => "Test message content",
            "timestamp" => 1732272000.0
        )

        parent_uri = "anamnesis:conv:parent-001"
        triples = RDF.message_to_rdf(message, parent_uri)

        @test length(triples) > 0

        # Should have message type triple
        @test any(t -> t.predicate == "rdf:type" && t.object == "anamnesis:Message", triples)

        # Should link to parent conversation
        @test any(t -> t.predicate == "anamnesis:partOf" && t.object == parent_uri, triples)

        # Should have content
        @test any(t -> t.predicate == "anamnesis:content", triples)
    end

    @testset "Artifact to RDF Conversion" begin
        artifact = Dict(
            "id" => "art-001",
            "type" => "code",
            "title" => "example.jl",
            "content" => "println(\"Hello, World!\")",
            "language" => "julia",
            "lifecycle_state" => "created"
        )

        parent_uri = "anamnesis:msg:parent-msg-001"
        triples = RDF.artifact_to_rdf(artifact, parent_uri)

        @test length(triples) > 0

        # Should have artifact type triple
        @test any(t -> t.predicate == "rdf:type" && t.object == "anamnesis:Artifact", triples)

        # Should have lifecycle state
        @test any(t -> t.predicate == "anamnesis:lifecycleState" &&
                      t.object == "anamnesis:lifecycle:created", triples)

        # Should have language
        @test any(t -> t.predicate == "anamnesis:language" && t.object == "\"julia\"", triples)
    end

    @testset "RDF Serialization to N-Triples" begin
        triples = [
            RDF.Triple(
                "anamnesis:conv:test-001",
                "rdf:type",
                "anamnesis:Conversation"
            ),
            RDF.Triple(
                "anamnesis:conv:test-001",
                "anamnesis:platform",
                "\"Claude\""
            ),
            RDF.Triple(
                "anamnesis:conv:test-001",
                "anamnesis:timestamp",
                "\"1732272000.0\"^^xsd:double"
            )
        ]

        ntriples_str = RDF.to_ntriples(triples)

        @test !isempty(ntriples_str)
        @test contains(ntriples_str, "<http://anamnesis.ai/ontology/conv:test-001>")
        @test contains(ntriples_str, "<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>")
        @test contains(ntriples_str, ".")  # N-Triples end with dots

        # Each line should end with a period
        lines = split(strip(ntriples_str), "\n")
        for line in lines
            @test endswith(strip(line), ".")
        end
    end

    @testset "URI Escaping" begin
        # Test that special characters in URIs are handled
        uri_with_spaces = RDF.escape_uri("test id with spaces")
        @test !contains(uri_with_spaces, " ")

        uri_with_special = RDF.escape_uri("test/id:with-special")
        # Should either escape or handle special chars
        @test !isempty(uri_with_special)
    end

    @testset "Literal Escaping" begin
        # Test that string literals are properly escaped
        literal_with_quotes = RDF.escape_literal("He said \"hello\"")
        @test contains(literal_with_quotes, "\\\"")

        literal_with_newline = RDF.escape_literal("Line 1\nLine 2")
        @test contains(literal_with_newline, "\\n")
    end

    @testset "Complete Pipeline Test" begin
        # Full conversation → RDF → N-Triples pipeline
        conversation = Dict(
            "id" => "pipeline-test-001",
            "platform" => "Claude",
            "timestamp" => 1732272000.0,
            "messages" => [
                Dict(
                    "id" => "msg-1",
                    "role" => "user",
                    "content" => "Create a Julia function",
                    "timestamp" => 1732272000.0,
                    "artifacts" => [
                        Dict(
                            "id" => "art-1",
                            "type" => "code",
                            "title" => "factorial.jl",
                            "content" => "factorial(n) = n <= 1 ? 1 : n * factorial(n-1)",
                            "language" => "julia",
                            "lifecycle_state" => "created"
                        )
                    ]
                ),
                Dict(
                    "id" => "msg-2",
                    "role" => "assistant",
                    "content" => "Here's a factorial function",
                    "timestamp" => 1732272010.0
                )
            ]
        )

        # Convert to RDF
        triples = RDF.conversation_to_rdf(conversation)
        @test length(triples) > 5  # Should have multiple triples

        # Serialize to N-Triples
        ntriples = RDF.to_ntriples(triples)
        @test !isempty(ntriples)

        # Should contain conversation, message, and artifact triples
        @test contains(ntriples, "Conversation")
        @test contains(ntriples, "Message")
        @test contains(ntriples, "Artifact")
    end
end

@testset "Port Interface Tests" begin
    @testset "Request Structure" begin
        # Test that we can create valid request structures
        request = Dict(
            "action" => "generate_rdf",
            "conversation" => Dict("id" => "test")
        )

        @test haskey(request, "action")
        @test haskey(request, "conversation")
    end

    @testset "Response Structure" begin
        # Test response format
        success_response = Dict(
            "status" => "ok",
            "result" => "RDF data here"
        )

        @test success_response["status"] == "ok"

        error_response = Dict(
            "status" => "error",
            "message" => "Something went wrong"
        )

        @test error_response["status"] == "error"
        @test haskey(error_response, "message")
    end
end

println("\n✓ All Julia tests passed!")
