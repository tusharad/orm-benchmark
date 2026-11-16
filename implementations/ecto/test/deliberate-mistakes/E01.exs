# E01: Type Mismatch in Equality
import Ecto.Query
alias EctoAirBench.{Repo, Schemas.Flight}

query = from f in Flight, where: f.flight_id == "INVALID"
Repo.all(query)
