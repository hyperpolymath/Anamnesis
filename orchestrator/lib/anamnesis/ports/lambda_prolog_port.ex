# SPDX-License-Identifier: AGPL-3.0-or-later

defmodule Anamnesis.Ports.LambdaPrologPort do
  @moduledoc """
  GenServer managing λProlog/ELPI reasoning port process.

  Communicates with the OCaml-based ELPI reasoner for:
  - Artifact lifecycle state machine queries
  - Fuzzy category membership reasoning
  - Cross-conversation contamination detection
  - Episodic memory queries
  """

  use GenServer
  require Logger

  @port_path Application.compile_env(
               :anamnesis,
               :lambda_prolog_port_path,
               "../reasoning/_build/default/bin/reasoner_port.exe"
             )
  @call_timeout 30_000

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Reason about a conversation to extract inferences.

  Returns {:ok, inferences} where inferences is a list of deduced facts.
  """
  @spec reason(map()) :: {:ok, list()} | {:error, term()}
  def reason(conversation) do
    GenServer.call(__MODULE__, {:reason, conversation}, @call_timeout)
  end

  @doc """
  Query artifact lifecycle state at a given timestamp.

  Returns {:ok, state} where state is one of :created, :modified, :removed, :evaluated
  """
  @spec artifact_state(String.t(), integer()) :: {:ok, atom()} | {:error, term()}
  def artifact_state(artifact_id, timestamp) do
    GenServer.call(__MODULE__, {:artifact_state, artifact_id, timestamp}, @call_timeout)
  end

  @doc """
  Detect contamination between conversations.

  Returns {:ok, contamination_report} with cross-project contamination details.
  """
  @spec detect_contamination(String.t()) :: {:ok, map()} | {:error, term()}
  def detect_contamination(conversation_id) do
    GenServer.call(__MODULE__, {:detect_contamination, conversation_id}, @call_timeout)
  end

  @doc """
  Query fuzzy category membership for a conversation.

  Returns {:ok, memberships} where memberships is a list of {category, strength} tuples.
  """
  @spec fuzzy_membership(String.t()) :: {:ok, list({String.t(), float()})} | {:error, term()}
  def fuzzy_membership(conversation_id) do
    GenServer.call(__MODULE__, {:fuzzy_membership, conversation_id}, @call_timeout)
  end

  @doc """
  Execute a raw λProlog query.

  Returns {:ok, bindings} with query variable bindings.
  """
  @spec query(String.t()) :: {:ok, map()} | {:error, term()}
  def query(query_string) do
    GenServer.call(__MODULE__, {:query, query_string}, @call_timeout)
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    port =
      Port.open(
        {:spawn, @port_path},
        [:binary, {:packet, 4}, :exit_status]
      )

    state = %{
      port: port,
      pending: %{},
      next_ref: 0
    }

    Logger.info("LambdaPrologPort started with port: #{inspect(port)}")
    {:ok, state}
  end

  @impl true
  def handle_call({:reason, conversation}, from, state) do
    ref = make_ref()

    request = %{
      ref: ref,
      action: :reason,
      conversation: conversation
    }

    encoded = :erlang.term_to_binary(request)
    Port.command(state.port, encoded)

    new_state = %{state | pending: Map.put(state.pending, ref, from)}
    {:noreply, new_state}
  end

  @impl true
  def handle_call({:artifact_state, artifact_id, timestamp}, from, state) do
    ref = make_ref()

    request = %{
      ref: ref,
      action: :artifact_state,
      artifact_id: artifact_id,
      timestamp: timestamp
    }

    encoded = :erlang.term_to_binary(request)
    Port.command(state.port, encoded)

    new_state = %{state | pending: Map.put(state.pending, ref, from)}
    {:noreply, new_state}
  end

  @impl true
  def handle_call({:detect_contamination, conversation_id}, from, state) do
    ref = make_ref()

    request = %{
      ref: ref,
      action: :detect_contamination,
      conversation_id: conversation_id
    }

    encoded = :erlang.term_to_binary(request)
    Port.command(state.port, encoded)

    new_state = %{state | pending: Map.put(state.pending, ref, from)}
    {:noreply, new_state}
  end

  @impl true
  def handle_call({:fuzzy_membership, conversation_id}, from, state) do
    ref = make_ref()

    request = %{
      ref: ref,
      action: :fuzzy_membership,
      conversation_id: conversation_id
    }

    encoded = :erlang.term_to_binary(request)
    Port.command(state.port, encoded)

    new_state = %{state | pending: Map.put(state.pending, ref, from)}
    {:noreply, new_state}
  end

  @impl true
  def handle_call({:query, query_string}, from, state) do
    ref = make_ref()

    request = %{
      ref: ref,
      action: :raw_query,
      query: query_string
    }

    encoded = :erlang.term_to_binary(request)
    Port.command(state.port, encoded)

    new_state = %{state | pending: Map.put(state.pending, ref, from)}
    {:noreply, new_state}
  end

  @impl true
  def handle_info({port, {:data, data}}, %{port: port} = state) do
    response = :erlang.binary_to_term(data)

    case Map.pop(state.pending, response.ref) do
      {nil, _} ->
        Logger.warning("Received response for unknown ref: #{inspect(response.ref)}")
        {:noreply, state}

      {from, pending} ->
        GenServer.reply(from, response.result)
        {:noreply, %{state | pending: pending}}
    end
  end

  @impl true
  def handle_info({port, {:exit_status, status}}, %{port: port} = state) do
    Logger.error("LambdaPrologPort exited with status: #{status}")

    Enum.each(state.pending, fn {_ref, from} ->
      GenServer.reply(from, {:error, :port_crashed})
    end)

    {:stop, {:port_exit, status}, state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.info("LambdaPrologPort terminating: #{inspect(reason)}")
    Port.close(state.port)
    :ok
  end
end
