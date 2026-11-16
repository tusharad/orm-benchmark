{-# LANGUAGE OverloadedStrings #-}
module E06_UnknownColumn where

import Database.Beam
import Database.Beam.PostgresAir.Schema

-- E06: Field typo / non-existent record field
badField :: Q Postgres PostgresAirDb s (QExpr Postgres s a)
badField = do
  f <- all_ (_flights postgresAirDb)
  pure (_flightNumberTypo f)
