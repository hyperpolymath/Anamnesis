# SPDX-License-Identifier: AGPL-3.0-or-later

defmodule Anamnesis.Ports.JuliaPort do
  @moduledoc """
  GenServer managing Julia analytics port process.

  Communicates with the Julia-based analytics engine for:
  - RDF triple generation from conversations
  - SPARQL query execution
  - Graph analysis and conversion
  - Reservoir computing / ESN training
  """

  use GenServer
  require Logger

  @port_path Application.compile_env(
               :anamnesis,
               :julia_port_path,
               "julia --project=../learning ../learning/src/port_interface.jl"
             )
  @call_timeout 60_000

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Generate RDF triples from a parsed conversation.

  Returns {:ok, rdf_string} where rdf_string is N-Triples format.
  """
  @spec generate_rdf(map(), list()) :: {:ok, String.t()} | {:error, term()}
  def generate_rdf(conversation, inferences \\ []) do
    GenServer.call(__MODULE__, {:generate_rdf, conversation, inferences}, @call_timeout)
  end

  @doc """
  Execute a SPARQL query against an endpoint.

  Returns {:ok, results} where results is a list of binding maps.
  """
  @spec sparql_query(String.t(), String.t()) :: {:ok, list(map())} | {:error, term()}
  def sparql_query(endpoint, query) do
    GenServer.call(__MODULE__, {:sparql_query, endpoint, query}, @call_timeout)
  end

  @doc """
  Convert RDF to a MetaGraph structure.

  Returns {:ok, graph_json} with serialized graph data.
  """
  @spec rdf_to_graph(list(map())) :: {:ok, map()} | {:error, term()}
  def rdf_to_graph(sparql_results) do
    GenServer.call(__MODULE__, {:rdf_to_metagraph, sparql_results}, @call_timeout)
  end

  @doc """
  Insert RDF data into Virtuoso.
  """
  @spec virtuoso_insert(String.t(), String.t()) :: :ok | {:error, term()}
  def virtuoso_insert(endpoint, rdf) do
    GenServer.call(__MODULE__, {:virtuoso_insert, endpoint, rdf}, @call_timeout)
  end

  @doc """
  Get conversation embedding.

  Returns {:ok, embedding} where embedding is a list of floats.
  """
  @spec conversation_embedding(map()) :: {:ok, list(float())} | {:error, term()}
  def conversation_embedding(conversation) do
    GenServer.call(__MODULE__, {:conversation_embedding, conversation}, @call_timeout)
  end

  @doc """
  Analyze a conversation graph.

  Returns {:ok, metrics} with graph analysis results.
  """
  @spec analyze_graph(map()) :: {:ok, map()} | {:error, term()}
  def analyze_graph(graph_data) do
    GenServer.call(__MODULE__, {:analyze_graph, graph_data}, @call_timeout)
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    port =
      Port.open(
        {:spawn, @port_path},
        [:binary, {:packet, 4}, :exit_status, :use_stdio]
      )

    state = %{
      port: port,
      pending: %{}
    }

    Logger.info("JuliaPort started with port: #{inspect(port)}")
    {:ok, state}
  end

  @impl true
  def handle_call({:generate_rdf, conversation, inferences}, from, state) do
    request =
      Jason.encode!(%{
        action: "generate_rdf",
        conversation: conversation,
        inferences: inferences
      })

    send_request(state.port, request)

    ref = make_ref()
    new_state = %{state | pending: Map.put(state.pending, ref, from)}
    {:noreply, new_state}
  end

  @impl true
  def handle_call({:sparql_query, endpoint, query}, from, state) do
    request =
      Jason.encode!(%{
        action: "sparql_query",
        endpoint: endpoint,
        query: query
      })

    send_request(state.port, request)

    ref = make_ref()
    new_state = %{state | pending: Map.put(state.pending, ref, from)}
    {:noreply, new_state}
  end

  @impl true
  def handle_call({:rdf_to_metagraph, sparql_results}, from, state) do
    request =
      Jason.encode!(%{
        action: "rdf_to_metagraph",
        sparql_results: sparql_results
      })

    send_request(state.port, request)

    ref = make_ref()
    new_state = %{state | pending: Map.put(state.pending, ref, from)}
    {:noreply, new_state}
  end

  @impl true
  def handle_call({:virtuoso_insert, endpoint, rdf}, from, state) do
    request =
      Jason.encode!(%{
        action: "virtuoso_insert",
        endpoint: endpoint,
        rdf: rdf
      })

    send_request(state.port, request)

    ref = make_ref()
    new_state = %{state | pending: Map.put(state.pending, ref, from)}
    {:noreply, new_state}
  end

  @impl true
  def handle_call({:conversation_embedding, conversation}, from, state) do
    request =
      Jason.encode!(%{
        action: "conversation_embedding",
        conversation: conversation
      })

    send_request(state.port, request)

    ref = make_ref()
    new_state = %{state | pending: Map.put(state.pending, ref, from)}
    {:noreply, new_state}
  end

  @impl true
  def handle_call({:analyze_graph, graph_data}, from, state) do
    request =
      Jason.encode!(%{
        action: "analyze_graph",
        graph: graph_data
      })

    send_request(state.port, request)

    ref = make_ref()
    new_state = %{state | pending: Map.put(state.pending, ref, from)}
    {:noreply, new_state}
  end

  @impl true
  def handle_info({port, {:data, data}}, %{port: port} = state) do
    case Jason.decode(data) do
      {:ok, response} ->
        # For simplicity, reply to the first pending request
        case Map.to_list(state.pending) do
          [{ref, from} | _] ->
            result =
              if response["error"] do
                {:error, response["error"]}
              else
                {:ok, response["result"]}
              end

            GenServer.reply(from, result)
            {:noreply, %{state | pending: Map.delete(state.pending, ref)}}

          [] ->
            Logger.warning("Received response with no pending requests")
            {:noreply, state}
        end

      {:error, _} ->
        Logger.error("Failed to decode Julia response: #{inspect(data)}")
        {:noreply, state}
    end
  end

  @impl true
  def handle_info({port, {:exit_status, status}}, %{port: port} = state) do
    Logger.error("JuliaPort exited with status: #{status}")

    Enum.each(state.pending, fn {_ref, from} ->
      GenServer.reply(from, {:error, :port_crashed})
    end)

    {:stop, {:port_exit, status}, state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.info("JuliaPort terminating: #{inspect(reason)}")
    Port.close(state.port)
    :ok
  end

  # Private Functions

  defp send_request(port, json_string) do
    len = byte_size(json_string)
    # 4-byte big-endian length prefix
    header = <<len::big-unsigned-32>>
    Port.command(port, header <> json_string)
  end
end
