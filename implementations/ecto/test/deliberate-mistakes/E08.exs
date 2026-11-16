# E08: Dangling Join / Unbound Table Alias
import Ecto.Query
alias EctoAirBench.{Repo, Schemas.Flight}

query = from f in Flight, where: unbound_alias.flight_id == 1
Repo.all(query)
