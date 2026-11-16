{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE TypeApplications #-}
module E06_UnknownColumn where
import IHP.QueryBuilder
import IHP.Record ((|>))
import Models

-- E06: Unknown column name
badQuery = query @Flight |> filterWhere (#flightNoSuchField, "test")
