# Orchestrator Component (Elixir)

Fault-tolerant process supervision and coordination for Anamnesis.

## Purpose

Coordinate parsing, reasoning, analytics, and storage layers using OTP supervision trees and process pools. Provide HTTP API for visualization layer.

## Technology Stack

- **Elixir** 1.15+
- **Phoenix** 1.7+ - Web framework
- **Poolboy** - Process pooling
- **GenStage** - Backpressure handling
- **Telemetry** - Metrics and observability

## Directory Structure

```
orchestrator/
├── lib/
│   ├── anamnesis/
│   │   ├── application.ex          # OTP application
│   │   ├── ports/
│   │   │   ├── parser_port.ex      # OCaml parser pool
│   │   │   ├── lambda_prolog_port.ex  # λProlog reasoner
│   │   │   └── julia_port.ex       # Julia analytics
│   │   ├── pipelines/
│   │   │   ├── ingestion_pipeline.ex  # Conversation ingestion
│   │   │   └── query_pipeline.ex      # Query processing
│   │   ├── cache_manager.ex        # ETS-backed caching
│   │   └── virtuoso/
│   │       └── client.ex           # SPARQL client
│   ├── anamnesis_web/
│   │   ├── endpoint.ex             # Phoenix endpoint
│   │   ├── router.ex               # HTTP routes
│   │   └── controllers/
│   │       ├── conversation_controller.ex
│   │       └── query_controller.ex
│   └── anamnesis.ex                # Main module
├── config/
│   ├── config.exs
│   ├── dev.exs
│   ├── test.exs
│   └── prod.exs
├── test/
│   ├── anamnesis/
│   │   ├── ports/
│   │   │   └── parser_port_test.exs
│   │   └── pipelines/
│   │       └── ingestion_pipeline_test.exs
│   └── anamnesis_web/
│       └── controllers/
│           └── conversation_controller_test.exs
├── mix.exs
└── README.md                       # This file
```

## Key Concepts

### Supervision Tree

```
Anamnesis.Application
├── Anamnesis.PortSupervisor (one_for_one)
│   ├── Anamnesis.Ports.ParserPool (DynamicSupervisor)
│   │   ├── ParserPort.Worker #1
│   │   ├── ParserPort.Worker #2
│   │   ├── ParserPort.Worker #3
│   │   └── ParserPort.Worker #4
│   ├── Anamnesis.Ports.LambdaPrologPort (GenServer)
│   └── Anamnesis.Ports.JuliaPort (GenServer)
├── Anamnesis.Pipelines.IngestionPipeline (GenServer)
├── Anamnesis.Pipelines.QueryPipeline (GenServer)
├── Anamnesis.CacheManager (GenServer + ETS)
└── AnamnesisWeb.Endpoint (Phoenix)
```

### Port Communication Pattern

```elixir
defmodule Anamnesis.Ports.ParserPort do
  use GenServer

  def parse(content, format \\ :auto) do
    GenServer.call(__MODULE__, {:parse, content, format}, 30_000)
  end

  def handle_call({:parse, content, format}, from, state) do
    ref = make_ref()
    request = encode_request(ref, :parse, content, format)
    Port.command(state.port, request)
    {:noreply, %{state | pending: Map.put(state.pending, ref, from)}}
  end

  def handle_info({port, {:data, data}}, %{port: port} = state) do
    {ref, result} = decode_response(data)
    {from, pending} = Map.pop!(state.pending, ref)
    GenServer.reply(from, result)
    {:noreply, %{state | pending: pending}}
  end
end
```

### Ingestion Pipeline

```elixir
defmodule Anamnesis.Pipelines.IngestionPipeline do
  use GenServer

  def ingest_conversation(file_path) do
    GenServer.call(__MODULE__, {:ingest, file_path})
  end

  def handle_call({:ingest, file_path}, _from, state) do
    result = with \
      {:ok, content} <- File.read(file_path),
      {:ok, ast} <- parse_conversation(content),
      {:ok, inferences} <- reason_about_conversation(ast),
      {:ok, rdf} <- generate_rdf(ast, inferences),
      {:ok, _} <- store_in_virtuoso(rdf)
    do
      {:ok, ast.id}
    end

    {:reply, result, state}
  end

  defp parse_conversation(content) do
    Anamnesis.Ports.ParserPort.parse(content)
  end

  defp reason_about_conversation(ast) do
    Anamnesis.Ports.LambdaPrologPort.reason(ast)
  end

  defp generate_rdf(ast, inferences) do
    Anamnesis.Ports.JuliaPort.generate_rdf(ast, inferences)
  end

  defp store_in_virtuoso(rdf) do
    Anamnesis.Virtuoso.Client.insert(rdf)
  end
end
```

## Building

### Prerequisites

```bash
# Install Elixir 1.15+
asdf install elixir 1.15.7-otp-26
asdf local elixir 1.15.7-otp-26

# OR using package manager
brew install elixir  # macOS
```

### Install Dependencies

```bash
cd orchestrator
mix deps.get
```

### Configuration

```elixir
# config/dev.exs
import Config

config :anamnesis,
  virtuoso_endpoint: "http://localhost:8890/sparql",
  parser_port_path: "../parser/_build/default/bin/parser_port.exe",
  lambda_prolog_path: "../reasoning/_build/reasoner",
  julia_port_path: "../learning/julia_port.jl",
  parser_pool_size: 4

config :anamnesis, AnamnesisWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true
```

### Build & Run

```bash
# Compile
mix compile

# Run tests
mix test

# Start interactive shell
iex -S mix

# Start Phoenix server
mix phx.server
```

## Usage

### Ingest Conversation

```elixir
# iex
Anamnesis.Pipelines.IngestionPipeline.ingest_conversation("path/to/conversation.json")
# => {:ok, "conversation-uuid"}
```

### Query via HTTP

```bash
# Get conversation
curl http://localhost:4000/api/conversations/conv-123

# SPARQL query
curl -X POST http://localhost:4000/api/query \
  -H "Content-Type: application/json" \
  -d '{"sparql": "SELECT ?s ?p ?o WHERE { ?s ?p ?o } LIMIT 10"}'

# Find contaminated conversations
curl http://localhost:4000/api/contamination
```

### Direct Port Communication

```elixir
# Parse conversation
{:ok, conversation} = Anamnesis.Ports.ParserPort.parse(
  File.read!("conversation.json"),
  :claude
)

# Reason about it
{:ok, inferences} = Anamnesis.Ports.LambdaPrologPort.reason(conversation)

# Generate RDF
{:ok, rdf} = Anamnesis.Ports.JuliaPort.generate_rdf(conversation, inferences)

# Store
Anamnesis.Virtuoso.Client.insert(rdf)
```

## Testing

### Unit Tests

```elixir
# test/anamnesis/ports/parser_port_test.exs
defmodule Anamnesis.Ports.ParserPortTest do
  use ExUnit.Case

  setup do
    {:ok, pid} = Anamnesis.Ports.ParserPort.start_link()
    %{port: pid}
  end

  test "parses Claude conversation", %{port: _port} do
    content = File.read!("test/fixtures/claude_conversation.json")
    {:ok, conv} = Anamnesis.Ports.ParserPort.parse(content, :claude)

    assert conv.platform == "claude"
    assert length(conv.messages) > 0
  end

  test "handles parse errors gracefully" do
    {:error, _reason} = Anamnesis.Ports.ParserPort.parse("invalid json")
  end
end
```

### Integration Tests

```elixir
# test/anamnesis/pipelines/ingestion_pipeline_test.exs
defmodule Anamnesis.Pipelines.IngestionPipelineTest do
  use ExUnit.Case

  @tag :integration
  test "end-to-end ingestion" do
    file = "test/fixtures/full_conversation.json"
    {:ok, conv_id} = Anamnesis.Pipelines.IngestionPipeline.ingest_conversation(file)

    # Verify in Virtuoso
    query = "SELECT ?s WHERE { ?s a anamnesis:Conversation }"
    {:ok, results} = Anamnesis.Virtuoso.Client.query(query)

    assert Enum.any?(results, fn r -> r["s"] == "anamnesis:conv:#{conv_id}" end)
  end
end
```

## Performance

### Pooling Strategy

```elixir
# Use Poolboy for parser workers
:poolboy.checkout(Anamnesis.Ports.ParserPool, false, 5000)
```

### Caching

```elixir
# ETS cache for frequent queries
defmodule Anamnesis.CacheManager do
  use GenServer

  def get(key) do
    case :ets.lookup(:anamnesis_cache, key) do
      [{^key, value}] -> {:ok, value}
      [] -> :miss
    end
  end

  def put(key, value, ttl \\ 3600) do
    :ets.insert(:anamnesis_cache, {key, value, :os.system_time(:second) + ttl})
  end
end
```

### Backpressure

```elixir
# Use GenStage for ingestion pipeline
defmodule Anamnesis.Pipelines.IngestionProducer do
  use GenStage

  def start_link(_) do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  # Producer-consumer pattern for rate limiting
end
```

## Monitoring

### Telemetry Events

```elixir
:telemetry.execute(
  [:anamnesis, :parser, :parse],
  %{duration: duration_ms},
  %{format: format, size: byte_size}
)

:telemetry.execute(
  [:anamnesis, :pipeline, :ingest],
  %{duration: total_ms},
  %{conversation_id: conv_id, success: true}
)
```

### Attach Handlers

```elixir
# lib/anamnesis/telemetry.ex
:telemetry.attach_many(
  "anamnesis-metrics",
  [
    [:anamnesis, :parser, :parse],
    [:anamnesis, :pipeline, :ingest]
  ],
  &handle_event/4,
  nil
)

defp handle_event(event_name, measurements, metadata, _config) do
  Logger.info("Event: #{inspect(event_name)}, duration: #{measurements.duration}ms")
end
```

## Deployment

### Production Config

```elixir
# config/prod.exs
config :anamnesis,
  virtuoso_endpoint: System.get_env("VIRTUOSO_ENDPOINT"),
  parser_pool_size: String.to_integer(System.get_env("PARSER_POOL_SIZE", "8"))

config :anamnesis, AnamnesisWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT", "4000"))],
  url: [host: System.get_env("HOST"), port: 443, scheme: "https"],
  secret_key_base: System.get_env("SECRET_KEY_BASE")
```

### Release

```bash
# Build release
MIX_ENV=prod mix release

# Run
_build/prod/rel/anamnesis/bin/anamnesis start
```

### Docker

```dockerfile
FROM elixir:1.15-alpine

WORKDIR /app

COPY mix.exs mix.lock ./
RUN mix deps.get --only prod

COPY . .
RUN MIX_ENV=prod mix compile
RUN MIX_ENV=prod mix release

CMD ["_build/prod/rel/anamnesis/bin/anamnesis", "start"]
```

## Troubleshooting

### Port Timeout

Increase timeout in GenServer.call:

```elixir
GenServer.call(port, request, 60_000)  # 60 seconds
```

### Port Crashes

Check supervision tree restart intensity:

```elixir
# lib/anamnesis/port_supervisor.ex
Supervisor.start_link(children, strategy: :one_for_one, max_restarts: 10, max_seconds: 60)
```

### Memory Leaks

Use `:observer` to profile:

```elixir
iex> :observer.start()
```

## References

- [Elixir Documentation](https://hexdocs.pm/elixir/)
- [Phoenix Framework](https://hexdocs.pm/phoenix/)
- [GenStage & Flow](https://hexdocs.pm/gen_stage/)
- Architecture: `/docs/architecture/system-architecture.adoc`
- Integration Guide: `/docs/guides/ocaml-elixir-integration.adoc`

## Next Steps

1. Implement ParserPort GenServer
2. Create IngestionPipeline
3. Integrate Virtuoso client
4. Add Phoenix HTTP API
5. Implement caching layer
6. Add Telemetry metrics
