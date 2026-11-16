{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE TypeApplications #-}
module E01_TypeMismatch where
import IHP.QueryBuilder
import IHP.Record ((|>))
import Models

-- E01: flightNo is Text, passing Int
badQuery = query @Flight |> filterWhere (#flightNo, 12345 :: Int)
