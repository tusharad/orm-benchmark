{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE OverloadedStrings #-}

module E05_NullabilityViolation where

import Data.Time (UTCTime)
import qualified GHC.Generics as GHC
import qualified Generics.SOP as SOP
import Squeal.PostgreSQL
import Schema

data BadFlight = BadFlight
  { actual_departure :: UTCTime
  } deriving stock (GHC.Generic)
    deriving anyclass (SOP.Generic, SOP.HasDatatypeInfo)

-- E05: Attempting to decode nullable actual_departure as non-nullable UTCTime
badNull :: Query_ DB () BadFlight
badNull = select_ (#f ! #actual_departure `as` #actual_departure :* Nil)
  (from (table ((#postgres_air ! #flight) `as` #f)))
