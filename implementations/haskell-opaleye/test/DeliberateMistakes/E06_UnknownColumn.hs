{-# LANGUAGE OverloadedStrings #-}
module E06_UnknownColumn where

import Opaleye
import Database.Opaleye.PostgresAir.Schema
import Data.Int (Int32)

-- E06: Field typo / non-existent record field
badField :: Select ()
badField = do
  f <- selectTable flightTable
  where_ (nonExistentField f .== toFields (1 :: Int32))
