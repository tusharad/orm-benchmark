{-# LANGUAGE OverloadedStrings #-}
module E04_IoEscape where

import Database.Beam
import Database.Beam.PostgresAir.Schema
import Data.Text (Text)

-- E04: Calling IO action inside pure Beam query comprehension
badIo :: Q Postgres PostgresAirDb s (QExpr Postgres s Text)
badIo = do
  f <- all_ (_flights postgresAirDb)
  putStrLn "Side effect inside pure query"
  pure (_flightNo f)
