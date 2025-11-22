defmodule Anamnesis.Application do
  @moduledoc """
  Anamnesis OTP Application

  Supervision tree for conversation knowledge extraction system.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Port Supervisor (manages OCaml, λProlog, Julia ports)
      {Anamnesis.PortSupervisor, []},

      # Cache Manager (ETS-backed caching)
      {Anamnesis.CacheManager, []},

      # Pipelines
      {Anamnesis.Pipelines.IngestionPipeline, []},
      {Anamnesis.Pipelines.QueryPipeline, []},

      # Telemetry supervisor
      AnamnesisWeb.Telemetry,

      # Phoenix PubSub
      {Phoenix.PubSub, name: Anamnesis.PubSub},

      # Phoenix Endpoint
      AnamnesisWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Anamnesis.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AnamnesisWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
