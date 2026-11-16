defmodule EctoAirBench.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      EctoAirBench.Repo
    ]

    opts = [strategy: :one_for_one, name: EctoAirBench.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
