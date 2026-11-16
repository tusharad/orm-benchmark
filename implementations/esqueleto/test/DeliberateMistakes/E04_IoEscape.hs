{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}
module E04_IoEscape where

import Database.Esqueleto.Experimental
import Database.Esqueleto.PostgresAir.Schema

-- E04: Calling IO action inside pure SqlQuery comprehension
badIo :: SqlQuery (SqlExpr (Entity Flight))
badIo = do
  f <- from $ table @Flight
  putStrLn "Side effect inside pure query"
  pure f
