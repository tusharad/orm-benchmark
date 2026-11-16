{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE TypeApplications #-}
module E05_NullabilityViolation where
import IHP.QueryBuilder
import IHP.Record ((|>))
import Models

-- E05: actualDeparture is Maybe UTCTime, passing Int
badQuery = query @Flight |> filterWhere (#actualDeparture, 123 :: Int)
