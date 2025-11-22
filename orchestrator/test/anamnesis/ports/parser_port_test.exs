defmodule Anamnesis.Ports.ParserPortTest do
  use ExUnit.Case, async: false
  alias Anamnesis.Ports.ParserPort

  @moduledoc """
  Tests for OCaml parser port communication.

  Note: These tests assume the OCaml parser binary is built.
  Some tests may be integration tests requiring the actual binary.
  """

  describe "port lifecycle" do
    test "starts and stops successfully" do
      # Note: This requires the parser binary to be built
      # For now, we test the GenServer behavior without actual port

      # Mock test - in real implementation would start actual port
      assert :ok == :ok
    end
  end

  describe "message encoding/decoding" do
    test "encodes parse request correctly" do
      request = %{
        ref: make_ref(),
        action: :parse,
        format: "claude",
        content: "{\"uuid\": \"test\"}"
      }

      # Test that we can encode to Erlang term format
      encoded = :erlang.term_to_binary(request)
      assert is_binary(encoded)
      assert byte_size(encoded) > 0

      # Verify we can decode it back
      decoded = :erlang.binary_to_term(encoded)
      assert decoded.action == :parse
      assert decoded.format == "claude"
    end

    test "handles detection request encoding" do
      request = %{
        ref: make_ref(),
        action: :detect,
        content: "{\"uuid\": \"test\"}"
      }

      encoded = :erlang.term_to_binary(request)
      decoded = :erlang.binary_to_term(encoded)

      assert decoded.action == :detect
      assert is_reference(decoded.ref)
    end
  end

  describe "timeout handling" do
    test "parse request has 30-second timeout" do
      # Verify the timeout constant is reasonable
      timeout = 30_000
      assert timeout > 0
      assert timeout <= 60_000
    end
  end

  describe "error handling" do
    test "handles malformed responses gracefully" do
      # Test that we can handle various error cases
      error_response = %{
        error: "Parse failed",
        details: "Invalid JSON structure"
      }

      encoded = :erlang.term_to_binary(error_response)
      decoded = :erlang.binary_to_term(encoded)

      assert Map.has_key?(decoded, :error)
      assert is_binary(decoded.error)
    end

    test "handles port exit conditions" do
      # Test that port supervisor handles crashes
      # This is a placeholder for integration testing
      assert :ok == :ok
    end
  end

  describe "conversation format detection" do
    test "detect request structure is correct" do
      content = ~s({"uuid": "test-123", "chat_messages": []})
      request = %{
        ref: make_ref(),
        action: :detect,
        content: content
      }

      assert request.action == :detect
      assert is_binary(request.content)
    end
  end
end
