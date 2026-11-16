{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}
module E05_NullabilityViolation where

import Database.Esqueleto.Experimental
import Database.Esqueleto.PostgresAir.Schema

-- E05: Assigning val Nothing to non-nullable column
badNullAssign :: SqlQuery ()
badNullAssign = do
  f <- from $ table @Flight
  where_ (f ^. FlightFlightNo ==. nothing)
