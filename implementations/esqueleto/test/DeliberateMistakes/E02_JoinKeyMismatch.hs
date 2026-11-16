{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}
module E02_JoinKeyMismatch where

import Database.Esqueleto.Experimental
import Database.Esqueleto.PostgresAir.Schema

-- E02: Equating Int32 flight_id with Int64 passenger_id
badJoin :: SqlQuery (SqlExpr (Value Bool))
badJoin = do
  (f :& p) <- from $
    table @Flight
    `innerJoin` table @Passenger
      `on` (\(f :& p) -> f ^. FlightFlightId ==. p ^. PassengerPassengerId)
  pure (val True)
