{-# LANGUAGE OverloadedStrings #-}
module E01_TypeMismatch where

import Opaleye
import Database.Opaleye.PostgresAir.Schema
import Data.Time (UTCTime)

-- E01: Comparing FieldNullable SqlTimestamptz to bare Field SqlTimestamptz with .==
badQuery :: UTCTime -> Select (Field SqlBool)
badQuery someTime = do
  f <- selectTable flightTable
  pure (actualDeparture f .== toFields someTime)
