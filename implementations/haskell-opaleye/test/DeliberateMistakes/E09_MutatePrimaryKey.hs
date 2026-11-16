{-# LANGUAGE OverloadedStrings #-}
module E09_MutatePrimaryKey where

import Opaleye
import Database.Opaleye.PostgresAir.Schema

-- E09: Assigning to non-assignable/immutable primary key
badPkUpdate :: Flight -> IO ()
badPkUpdate f = do
  flightId f = 999
