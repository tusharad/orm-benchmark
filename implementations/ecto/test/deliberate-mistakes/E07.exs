# E07: Window Function in WHERE Clause
import Ecto.Query
alias EctoAirBench.{Repo, Schemas.Flight}

query = from f in Flight, where: fragment("row_number() OVER () > 1")
Repo.all(query)
