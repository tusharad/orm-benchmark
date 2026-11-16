{-# LANGUAGE OverloadedStrings #-}
module E08_DanglingJoin where

import Opaleye
import Database.Opaleye.PostgresAir.Schema

-- E08: Referencing an unbound table alias
badDangling :: Select (Field SqlBool)
badDangling = do
  f <- selectTable flightTable
  pure (flightId f .== accAccountId unjoinedAccount)
