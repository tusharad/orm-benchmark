{-# LANGUAGE OverloadedStrings #-}
module E10_ScopeLeak where

import Database.Beam
import Database.Beam.PostgresAir.Schema

-- E10: Inner query scope alias leakage
badScope :: Q Postgres PostgresAirDb s (FlightT (QExpr Postgres s))
badScope = do
  let innerQuery = do
        innerFlight <- all_ (_flights postgresAirDb)
        pure (_flightId innerFlight)
  f <- all_ (_flights postgresAirDb)
  guard_ (_flightId f ==. _flightId innerFlight)
  pure f
