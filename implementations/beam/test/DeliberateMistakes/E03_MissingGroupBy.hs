{-# LANGUAGE OverloadedStrings #-}
module E03_MissingGroupBy where

import Database.Beam
import Database.Beam.PostgresAir.Schema
import Data.Text (Text)
import Data.Int (Int32)

-- E03: Selecting raw un-aggregated column in aggregate query without group_
badAgg :: Q Postgres PostgresAirDb s (QExpr Postgres s (Text, Int32))
badAgg = aggregate_ (\f -> (_departureAirport f, countAll_)) (all_ (_flights postgresAirDb))
