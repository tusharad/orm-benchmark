{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}
module E03_MissingGroupBy where

import Database.Esqueleto.Experimental
import Database.Esqueleto.PostgresAir.Schema
import Data.Text (Text)

-- E03: Selecting unaggregated column in aggregate query
badAgg :: SqlQuery (SqlExpr (Value Text), SqlExpr (Value (Maybe Int)))
badAgg = do
  f <- from $ table @Flight
  pure (f ^. FlightDepartureAirport, count (f ^. FlightFlightId))
