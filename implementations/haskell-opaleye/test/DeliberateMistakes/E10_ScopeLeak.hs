{-# LANGUAGE OverloadedStrings #-}
module E10_ScopeLeak where

import Opaleye
import Database.Opaleye.PostgresAir.Schema

-- E10: Inner query scope alias leakage
badScope :: Select FlightField
badScope = do
  let innerQuery = do
        innerFlight <- selectTable flightTable
        pure (flightId innerFlight)
  f <- selectTable flightTable
  where_ (flightId f .== flightId innerFlight)
  pure f
