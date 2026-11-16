{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}
module E06_UnknownColumn where

import Rel8
import Schema

-- E06: Field typo / non-existent record field
badField :: Query (Flight Expr)
badField = do
  f <- each flightSchema
  where_ (f.nonExistentColumn ==. lit 1)
  pure f
