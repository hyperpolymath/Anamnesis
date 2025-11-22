defmodule Anamnesis.Pipelines.IngestionPipeline do
  @moduledoc """
  Pipeline for ingesting conversations from files.

  Process:
  1. Read file
  2. Parse via OCaml port
  3. Reason via λProlog port
  4. Generate RDF via Julia port
  5. Store in Virtuoso
  """

  use GenServer
  require Logger

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Ingest a conversation file.

  Returns {:ok, conversation_id} or {:error, reason}
  """
  def ingest_file(file_path) do
    GenServer.call(__MODULE__, {:ingest_file, file_path}, 120_000)
  end

  @doc """
  Ingest raw conversation content with specified format.
  """
  def ingest_content(content, format \\ :auto) do
    GenServer.call(__MODULE__, {:ingest_content, content, format}, 120_000)
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:ingest_file, file_path}, _from, state) do
    Logger.info("Ingesting file: #{file_path}")

    result = with \
      {:ok, content} <- File.read(file_path),
      {:ok, conversation} <- parse_conversation(content),
      {:ok, inferences} <- reason_about_conversation(conversation),
      {:ok, rdf} <- generate_rdf(conversation, inferences),
      {:ok, _} <- store_in_virtuoso(rdf)
    do
      Logger.info("Successfully ingested conversation: #{conversation["id"]}")
      {:ok, conversation["id"]}
    else
      {:error, reason} = error ->
        Logger.error("Failed to ingest file #{file_path}: #{inspect(reason)}")
        error
    end

    {:reply, result, state}
  end

  @impl true
  def handle_call({:ingest_content, content, format}, _from, state) do
    Logger.info("Ingesting content with format: #{format}")

    result = with \
      {:ok, conversation} <- parse_conversation(content, format),
      {:ok, inferences} <- reason_about_conversation(conversation),
      {:ok, rdf} <- generate_rdf(conversation, inferences),
      {:ok, _} <- store_in_virtuoso(rdf)
    do
      {:ok, conversation["id"]}
    else
      {:error, reason} = error ->
        Logger.error("Failed to ingest content: #{inspect(reason)}")
        error
    end

    {:reply, result, state}
  end

  # Private Functions

  defp parse_conversation(content, format \\ :auto) do
    case Anamnesis.Ports.ParserPort.parse(content, format) do
      {:ok, conv} -> {:ok, conv}
      {:error, reason} -> {:error, {:parse_failed, reason}}
    end
  end

  defp reason_about_conversation(conversation) do
    case Anamnesis.Ports.LambdaPrologPort.reason(conversation) do
      {:ok, inferences} -> {:ok, inferences}
      {:error, reason} -> {:error, {:reasoning_failed, reason}}
    end
  end

  defp generate_rdf(conversation, inferences) do
    case Anamnesis.Ports.JuliaPort.generate_rdf(conversation, inferences) do
      {:ok, rdf} -> {:ok, rdf}
      {:error, reason} -> {:error, {:rdf_generation_failed, reason}}
    end
  end

  defp store_in_virtuoso(rdf) do
    endpoint = Application.get_env(:anamnesis, :virtuoso_endpoint)
    case Anamnesis.Virtuoso.Client.insert(endpoint, rdf) do
      :ok -> {:ok, :stored}
      {:error, reason} -> {:error, {:virtuoso_storage_failed, reason}}
    end
  end
end
