{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE TypeApplications #-}
module E02_JoinKeyMismatch where
import Data.Int (Int64)
import IHP.QueryBuilder
import IHP.Record ((|>))
import Models

-- E02: flightId is Int32, passing Int64
badQuery = query @Flight |> filterWhere (#flightId, 100 :: Int64)
