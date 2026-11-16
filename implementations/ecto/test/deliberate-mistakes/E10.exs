# E10: Inner Query Scope Leakage
import Ecto.Query
alias EctoAirBench.{Repo, Schemas.Flight, Schemas.BookingLeg}

sq = from bl in BookingLeg, where: bl.flight_id == 1, select: bl.booking_id
query = from f in Flight, where: f.flight_id in subquery(sq) and bl.booking_id == 100
Repo.all(query)
