{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}
module E01_TypeMismatch where

import Data.Time (UTCTime)
import Rel8
import Schema

-- E01: Comparing Maybe UTCTime to bare UTCTime
badQuery :: UTCTime -> Query (Flight Expr)
badQuery someTime = do
  f <- each flightSchema
  where_ (f.actualDeparture ==. lit someTime)
  pure f
