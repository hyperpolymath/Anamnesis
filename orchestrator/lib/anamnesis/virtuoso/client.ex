# SPDX-License-Identifier: AGPL-3.0-or-later

defmodule Anamnesis.Virtuoso.Client do
  @moduledoc """
  HTTP client for Virtuoso SPARQL endpoint.

  Provides direct SPARQL query execution and RDF data management
  for cases where the Julia port is not needed.
  """

  require Logger

  @default_timeout 30_000
  @default_headers [
    {"Accept", "application/sparql-results+json"},
    {"Content-Type", "application/sparql-query"}
  ]

  @doc """
  Execute a SPARQL SELECT query.

  Returns {:ok, results} where results is a list of binding maps.
  """
  @spec query(String.t(), String.t(), keyword()) :: {:ok, list(map())} | {:error, term()}
  def query(endpoint, sparql_query, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, @default_timeout)

    case HTTPoison.post(endpoint, sparql_query, @default_headers, recv_timeout: timeout) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        parse_sparql_results(body)

      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, {:request_failed, reason}}
    end
  end

  @doc """
  Execute a SPARQL ASK query.

  Returns {:ok, boolean} indicating the ASK result.
  """
  @spec ask(String.t(), String.t()) :: {:ok, boolean()} | {:error, term()}
  def ask(endpoint, sparql_query) do
    case HTTPoison.post(endpoint, sparql_query, @default_headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"boolean" => result}} -> {:ok, result}
          {:error, _} -> {:error, :parse_error}
        end

      {:ok, %HTTPoison.Response{status_code: status}} ->
        {:error, {:http_error, status}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, {:request_failed, reason}}
    end
  end

  @doc """
  Insert RDF data into Virtuoso.

  Accepts N-Triples format data. Optionally specify a named graph.
  """
  @spec insert(String.t(), String.t(), keyword()) :: :ok | {:error, term()}
  def insert(endpoint, rdf_data, opts \\ []) do
    graph = Keyword.get(opts, :graph)

    # Build SPARQL UPDATE query
    sparql =
      if graph do
        """
        INSERT DATA {
          GRAPH <#{graph}> {
            #{rdf_data}
          }
        }
        """
      else
        """
        INSERT DATA {
          #{rdf_data}
        }
        """
      end

    headers = [{"Content-Type", "application/sparql-update"}]

    case HTTPoison.post(endpoint, sparql, headers) do
      {:ok, %HTTPoison.Response{status_code: code}} when code in [200, 201, 204] ->
        :ok

      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, {:request_failed, reason}}
    end
  end

  @doc """
  Delete triples matching a pattern.
  """
  @spec delete(String.t(), String.t()) :: :ok | {:error, term()}
  def delete(endpoint, delete_pattern) do
    sparql = "DELETE WHERE { #{delete_pattern} }"
    headers = [{"Content-Type", "application/sparql-update"}]

    case HTTPoison.post(endpoint, sparql, headers) do
      {:ok, %HTTPoison.Response{status_code: code}} when code in [200, 204] ->
        :ok

      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, {:request_failed, reason}}
    end
  end

  @doc """
  Clear all triples from a named graph.
  """
  @spec clear_graph(String.t(), String.t()) :: :ok | {:error, term()}
  def clear_graph(endpoint, graph_uri) do
    sparql = "CLEAR GRAPH <#{graph_uri}>"
    headers = [{"Content-Type", "application/sparql-update"}]

    case HTTPoison.post(endpoint, sparql, headers) do
      {:ok, %HTTPoison.Response{status_code: code}} when code in [200, 204] ->
        :ok

      {:ok, %HTTPoison.Response{status_code: status}} ->
        {:error, {:http_error, status}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, {:request_failed, reason}}
    end
  end

  @doc """
  Drop a named graph entirely.
  """
  @spec drop_graph(String.t(), String.t(), keyword()) :: :ok | {:error, term()}
  def drop_graph(endpoint, graph_uri, opts \\ []) do
    silent = if Keyword.get(opts, :silent, true), do: "SILENT ", else: ""
    sparql = "DROP #{silent}GRAPH <#{graph_uri}>"
    headers = [{"Content-Type", "application/sparql-update"}]

    case HTTPoison.post(endpoint, sparql, headers) do
      {:ok, %HTTPoison.Response{status_code: code}} when code in [200, 204] ->
        :ok

      {:ok, %HTTPoison.Response{status_code: status}} ->
        {:error, {:http_error, status}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, {:request_failed, reason}}
    end
  end

  @doc """
  List all named graphs in the store.
  """
  @spec list_graphs(String.t()) :: {:ok, list(String.t())} | {:error, term()}
  def list_graphs(endpoint) do
    sparql = "SELECT DISTINCT ?g WHERE { GRAPH ?g { ?s ?p ?o } }"

    case query(endpoint, sparql) do
      {:ok, results} ->
        graphs = Enum.map(results, & &1["g"])
        {:ok, graphs}

      error ->
        error
    end
  end

  @doc """
  Count triples in a graph (or total if no graph specified).
  """
  @spec count_triples(String.t(), String.t() | nil) :: {:ok, integer()} | {:error, term()}
  def count_triples(endpoint, graph_uri \\ nil) do
    sparql =
      if graph_uri do
        "SELECT (COUNT(*) AS ?count) WHERE { GRAPH <#{graph_uri}> { ?s ?p ?o } }"
      else
        "SELECT (COUNT(*) AS ?count) WHERE { ?s ?p ?o }"
      end

    case query(endpoint, sparql) do
      {:ok, [%{"count" => count}]} ->
        {:ok, parse_integer(count)}

      {:ok, []} ->
        {:ok, 0}

      error ->
        error
    end
  end

  @doc """
  Check if Virtuoso endpoint is healthy.
  """
  @spec health_check(String.t()) :: :ok | {:error, term()}
  def health_check(endpoint) do
    case query(endpoint, "SELECT 1 WHERE { }") do
      {:ok, _} -> :ok
      error -> error
    end
  end

  # Private Functions

  defp parse_sparql_results(body) do
    case Jason.decode(body) do
      {:ok, %{"results" => %{"bindings" => bindings}}} ->
        results =
          Enum.map(bindings, fn row ->
            Map.new(row, fn {key, value} ->
              {key, extract_value(value)}
            end)
          end)

        {:ok, results}

      {:ok, _} ->
        {:error, :unexpected_format}

      {:error, _} ->
        {:error, :json_parse_error}
    end
  end

  defp extract_value(%{"value" => value, "type" => "uri"}), do: value
  defp extract_value(%{"value" => value, "type" => "bnode"}), do: "_:#{value}"

  defp extract_value(%{"value" => value, "datatype" => datatype}) do
    case datatype do
      "http://www.w3.org/2001/XMLSchema#integer" ->
        String.to_integer(value)

      "http://www.w3.org/2001/XMLSchema#float" ->
        String.to_float(value)

      "http://www.w3.org/2001/XMLSchema#double" ->
        String.to_float(value)

      "http://www.w3.org/2001/XMLSchema#boolean" ->
        value == "true"

      _ ->
        value
    end
  end

  defp extract_value(%{"value" => value}), do: value

  defp parse_integer(value) when is_integer(value), do: value
  defp parse_integer(value) when is_binary(value), do: String.to_integer(value)
  defp parse_integer(_), do: 0
end
