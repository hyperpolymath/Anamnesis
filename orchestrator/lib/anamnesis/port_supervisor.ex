defmodule Anamnesis.PortSupervisor do
  @moduledoc """
  Supervisor for all port processes (OCaml, λProlog, Julia).
  """

  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      # Parser pool (4 workers)
      {Anamnesis.Ports.ParserPool, pool_size: 4},

      # λProlog reasoner port (single instance)
      {Anamnesis.Ports.LambdaPrologPort, []},

      # Julia analytics port (single instance)
      {Anamnesis.Ports.JuliaPort, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
