{-# LANGUAGE OverloadedStrings #-}
module E05_NullabilityViolation where

import Database.Beam
import Database.Beam.PostgresAir.Schema

-- E05: Assigning val_ Nothing to non-nullable Text column
badNullAssign :: SqlUpdate Postgres AccountT
badNullAssign = update (_accounts postgresAirDb)
                       (\a -> _accountLogin a <-. val_ Nothing)
                       (\a -> _accountId a ==. val_ 1)
