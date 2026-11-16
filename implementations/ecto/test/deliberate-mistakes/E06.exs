# E06: Unknown Column Selection
import Ecto.Query
alias EctoAirBench.{Repo, Schemas.Flight}

query = from f in Flight, select: f.non_existent_column
Repo.all(query)
