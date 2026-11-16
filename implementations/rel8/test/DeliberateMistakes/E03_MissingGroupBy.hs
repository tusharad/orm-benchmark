{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}
module E03_MissingGroupBy where

import Data.Int (Int64)
import Data.Text (Text)
import Rel8
import Schema

-- E03: Selecting unaggregated column in aggregate query
badAgg :: Query (Expr Text, Expr Int64)
badAgg = aggregate do
  f <- each flightSchema
  pure (f.departureAirport, count f.flightId)
