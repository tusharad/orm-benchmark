{-# LANGUAGE OverloadedStrings #-}
module E07_WindowInWhere where

import Opaleye
import Database.Opaleye.PostgresAir.Schema
import Data.Int (Int64)

-- E07: Placing window function directly inside where_ expression
badWindowWhere :: Select FlightField
badWindowWhere = do
  f <- selectTable flightTable
  where_ (rowNumber .== toFields (1 :: Int64))
  pure f
