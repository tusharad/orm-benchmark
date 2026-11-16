{-# LANGUAGE OverloadedStrings #-}
module E09_MutatePrimaryKey where

import Database.Beam
import Database.Beam.PostgresAir.Schema

-- E09: Assigning to primary key in update assignment
badPkUpdate :: SqlUpdate Postgres AccountT
badPkUpdate = update (_accounts postgresAirDb)
                     (\a -> _accountId a <-. val_ 999)
                     (\a -> _accountId a ==. val_ 1)
