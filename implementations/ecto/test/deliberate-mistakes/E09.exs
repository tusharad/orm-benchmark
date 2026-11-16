# E09: Mutation of Immutable Primary Key
alias EctoAirBench.{Repo, Schemas.Flight}
import Ecto.Changeset

flight = Repo.get!(Flight, 1)
changeset = change(flight, flight_id: 2)
Repo.update!(changeset)
