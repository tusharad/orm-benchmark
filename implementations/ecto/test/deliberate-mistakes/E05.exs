# E05: Nullability Constraint Violation
alias EctoAirBench.{Repo, Schemas.Flight}

Repo.insert!(%Flight{flight_id: 999999, flight_no: nil, scheduled_departure: nil})
