{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}
module E10_ScopeLeak where

import Database.Esqueleto.Experimental
import Database.Esqueleto.PostgresAir.Schema

-- E10: Inner query scope alias leakage
badScope :: SqlQuery (SqlExpr (Entity Flight))
badScope = do
  let innerQuery = do
        innerFlight <- from $ table @Flight
        pure (innerFlight ^. FlightFlightId)
  f <- from $ table @Flight
  where_ (f ^. FlightFlightId ==. innerFlight ^. FlightFlightId)
  pure f
