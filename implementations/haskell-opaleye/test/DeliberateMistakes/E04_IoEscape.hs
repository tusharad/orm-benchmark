{-# LANGUAGE OverloadedStrings #-}
module E04_IoEscape where

import Opaleye
import Database.Opaleye.PostgresAir.Schema

-- E04: Calling IO action inside pure Select query
badIo :: Select FlightField
badIo = do
  f <- selectTable flightTable
  putStrLn "Side effect inside pure query"
  pure f
