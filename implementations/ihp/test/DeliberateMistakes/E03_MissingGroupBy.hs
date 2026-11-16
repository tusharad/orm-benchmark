{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE TypeApplications #-}
module E03_MissingGroupBy where
import IHP.QueryBuilder
import IHP.Record ((|>))
import Models

-- E03: Accessing non-existent column
badQuery = query @Flight |> filterWhere (#nonExistentField, "test")
