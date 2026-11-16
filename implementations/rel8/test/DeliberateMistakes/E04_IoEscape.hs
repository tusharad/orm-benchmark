{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}
module E04_IoEscape where

import Rel8
import Schema

-- E04: Calling IO action inside pure Query comprehension
badIo :: Query (Flight Expr)
badIo = do
  f <- each flightSchema
  putStrLn "Side effect inside pure query"
  pure f
