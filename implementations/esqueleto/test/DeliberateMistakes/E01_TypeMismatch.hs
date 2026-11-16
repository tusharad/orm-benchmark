{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}
module E01_TypeMismatch where

import Database.Esqueleto.Experimental
import Database.Esqueleto.PostgresAir.Schema
import Data.Time (UTCTime)

-- E01: Comparing Maybe UTCTime to bare UTCTime
badQuery :: UTCTime -> SqlQuery (SqlExpr (Value Bool))
badQuery someTime = do
  f <- from $ table @Flight
  pure (f ^. FlightActualDeparture ==. val someTime)
