{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE TypeApplications #-}
module E10_ScopeLeak where
import IHP.QueryBuilder
import IHP.Record ((|>))
import Models

-- E10: Undefined variable in filter
badQuery = query @Flight |> filterWhere (#flightId, undefinedVarScope)
