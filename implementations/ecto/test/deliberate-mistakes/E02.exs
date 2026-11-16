# E02: Key Mismatch in Join
import Ecto.Query
alias EctoAirBench.{Repo, Schemas.Flight}

query = from f in Flight, join: p in assoc(f, :passenger)
Repo.all(query)
