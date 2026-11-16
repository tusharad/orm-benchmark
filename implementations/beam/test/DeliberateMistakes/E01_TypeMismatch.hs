{-# LANGUAGE OverloadedStrings #-}
module E01_TypeMismatch where

import Database.Beam
import Database.Beam.PostgresAir.Schema
import Data.Time (UTCTime)

-- E01: Comparing Maybe UTCTime to bare UTCTime
badQuery :: UTCTime -> Q Postgres PostgresAirDb s (QExpr Postgres s Bool)
badQuery someTime = do
  f <- all_ (_flights postgresAirDb)
  pure (_actualDeparture f ==. val_ someTime)
