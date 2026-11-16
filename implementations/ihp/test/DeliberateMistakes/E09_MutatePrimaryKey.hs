{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE TypeApplications #-}
module E09_MutatePrimaryKey where
import IHP.QueryBuilder
import IHP.Record ((|>))
import Models

-- E09: Comparing primary key with incompatible String type
badQuery = query @Flight |> filterWhereGreaterThan (#flightId, "not-an-id" :: String)
