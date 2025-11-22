defmodule Anamnesis.Ports.ParserPort do
  @moduledoc """
  GenServer managing OCaml parser port process.

  Communicates via Erlang External Term Format (ETF) for type-safe
  message passing with Alberto library on OCaml side.
  """

  use GenServer
  require Logger

  @port_path Application.compile_env(:anamnesis, :parser_port_path, "../parser/_build/default/bin/parser_port.exe")
  @call_timeout 30_000  # 30 seconds

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Parse conversation content with automatic format detection.

  Returns {:ok, conversation_map} or {:error, reason}
  """
  def parse(content, format \\ :auto) do
    GenServer.call(__MODULE__, {:parse, content, format}, @call_timeout)
  end

  @doc """
  Detect conversation format without parsing.

  Returns {:ok, format_name} or {:error, :unknown}
  """
  def detect_format(content) do
    GenServer.call(__MODULE__, {:detect_format, content}, @call_timeout)
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    port = Port.open(
      {:spawn, @port_path},
      [:binary, {:packet, 4}, :exit_status]
    )

    state = %{
      port: port,
      pending: %{},  # ref => from
      next_ref: 0
    }

    Logger.info("ParserPort started with port: #{inspect(port)}")
    {:ok, state}
  end

  @impl true
  def handle_call({:parse, content, format}, from, state) do
    ref = make_ref()

    request = %{
      ref: ref,
      action: :parse,
      format: format,
      content: content
    }

    encoded = :erlang.term_to_binary(request)
    Port.command(state.port, encoded)

    new_state = %{state | pending: Map.put(state.pending, ref, from)}
    {:noreply, new_state}
  end

  @impl true
  def handle_call({:detect_format, content}, from, state) do
    ref = make_ref()

    request = %{
      ref: ref,
      action: :detect_format,
      content: content
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
        Logger.warn("Received response for unknown ref: #{inspect(response.ref)}")
        {:noreply, state}

      {from, pending} ->
        GenServer.reply(from, response.result)
        {:noreply, %{state | pending: pending}}
    end
  end

  @impl true
  def handle_info({port, {:exit_status, status}}, %{port: port} = state) do
    Logger.error("ParserPort exited with status: #{status}")
    # Reply to all pending requests with error
    Enum.each(state.pending, fn {_ref, from} ->
      GenServer.reply(from, {:error, :port_crashed})
    end)
    {:stop, {:port_exit, status}, state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.info("ParserPort terminating: #{inspect(reason)}")
    Port.close(state.port)
    :ok
  end
end
