{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE TypeApplications #-}
module E08_DanglingJoin where
import IHP.QueryBuilder
import IHP.Record ((|>))
import Models

-- E08: Incompatible type in whereIn list
badQuery = query @Flight |> filterWhereIn (#flightId, ["JFK", "LAX"])
