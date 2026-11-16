defmodule EctoAirBench.MixProject do
  use Mix.Project

  def project do
    [
      app: :ecto_air_bench,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {EctoAirBench.Application, []}
    ]
  end

  defp deps do
    [
      {:ecto, path: "..", override: true},
      {:ecto_sql, github: "elixir-ecto/ecto_sql"},
      {:postgrex, ">= 0.0.0"},
      {:jason, "~> 1.4"}
    ]
  end
end
