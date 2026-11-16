{-# LANGUAGE OverloadedStrings #-}
module E03_MissingGroupBy where

import Opaleye
import Database.Opaleye.PostgresAir.Schema

-- E03: Selecting unaggregated column alongside count in non-aggregated Select
badAgg :: Select (Field SqlBool)
badAgg = do
  f <- selectTable flightTable
  pure (flightId f .== count (flightId f))
