{-# LANGUAGE OverloadedStrings #-}
module E08_DanglingJoin where

import Database.Beam
import Database.Beam.PostgresAir.Schema

-- E08: Referencing an unbound table alias
badDangling :: Q Postgres PostgresAirDb s (QExpr Postgres s Bool)
badDangling = do
  f <- all_ (_flights postgresAirDb)
  pure (_flightId f ==. _accountId unjoinedAccount)
