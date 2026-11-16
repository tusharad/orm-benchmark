{-# LANGUAGE OverloadedStrings #-}
module E02_JoinKeyMismatch where

import Database.Beam
import Database.Beam.PostgresAir.Schema

-- E02: Equating Int32 flight_id with Int64 passenger_id
badJoin :: Q Postgres PostgresAirDb s (QExpr Postgres s Bool)
badJoin = do
  f <- all_ (_flights postgresAirDb)
  p <- all_ (_passengers postgresAirDb)
  pure (_flightId f ==. _passPassengerId p)
