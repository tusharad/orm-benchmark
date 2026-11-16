# E03: Missing GROUP BY Column
import Ecto.Query
alias EctoAirBench.{Repo, Schemas.Flight}

query = from f in Flight,
  group_by: f.departure_airport,
  select: {f.departure_airport, f.flight_no}
Repo.all(query)
