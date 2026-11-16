import Config

config :ecto_air_bench,
  ecto_repos: [EctoAirBench.Repo]

config :ecto_air_bench, EctoAirBench.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "postgres_air",
  hostname: "localhost",
  port: 5434,
  pool_size: 20,
  timeout: 15_000,
  queue_target: 5_000,
  after_connect: {Postgrex, :query!, ["SET search_path TO postgres_air, public", []]}

config :logger, level: :warning
