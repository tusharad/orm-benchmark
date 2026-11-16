{-# LANGUAGE OverloadedStrings #-}
module E07_WindowInWhere where

import Database.Beam
import Database.Beam.Query.Window
import Database.Beam.PostgresAir.Schema

-- E07: Placing window function directly inside guard_ / filter_ expression
badWindowWhere :: Q Postgres PostgresAirDb s (FlightT (QExpr Postgres s))
badWindowWhere = do
  f <- all_ (_flights postgresAirDb)
  guard_ (rowNumber_ (frame_ noPartition_ (orderPartitionBy_ (asc_ (_flightId f)))) ==. val_ 1)
  pure f
