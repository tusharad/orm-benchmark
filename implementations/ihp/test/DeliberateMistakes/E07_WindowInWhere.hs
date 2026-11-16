{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE TypeApplications #-}
module E07_WindowInWhere where
import IHP.QueryBuilder
import IHP.Record ((|>))
import Models

-- E07: Passing Bool to Int32 version field
badQuery = query @Flight |> filterWhere (#version, True)
