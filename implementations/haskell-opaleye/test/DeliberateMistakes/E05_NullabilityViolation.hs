{-# LANGUAGE OverloadedStrings #-}
module E05_NullabilityViolation where

import Opaleye
import Database.Opaleye.PostgresAir.Schema

-- E05: Assigning null to non-nullable column
badNullAssign :: Select ()
badNullAssign = do
  f <- selectTable flightTable
  where_ (flightNo f .== null)
