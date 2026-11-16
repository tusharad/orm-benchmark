{-# LANGUAGE OverloadedStrings #-}
module E02_JoinKeyMismatch where

import Opaleye
import Database.Opaleye.PostgresAir.Schema

-- E02: Equating Int32 flight_id with Int64 passenger_id
badJoin :: Select (Field SqlBool)
badJoin = do
  f <- selectTable flightTable
  p <- selectTable passengerTable
  pure (flightId f .== passengerId p)
