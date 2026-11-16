defmodule EctoAirBench.Repo do
  use Ecto.Repo,
    otp_app: :ecto_air_bench,
    adapter: Ecto.Adapters.Postgres
end
