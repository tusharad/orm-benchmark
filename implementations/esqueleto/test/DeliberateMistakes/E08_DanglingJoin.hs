{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}
module E08_DanglingJoin where

import Database.Esqueleto.Experimental
import Database.Esqueleto.PostgresAir.Schema

-- E08: Referencing an unbound table alias
badDangling :: SqlQuery (SqlExpr (Value Bool))
badDangling = do
  f <- from $ table @Flight
  pure (f ^. FlightFlightId ==. unjoinedAccount ^. AccountAccountId)
