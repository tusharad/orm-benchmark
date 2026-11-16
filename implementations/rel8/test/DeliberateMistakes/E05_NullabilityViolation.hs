{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}
module E05_NullabilityViolation where

import Rel8
import Schema

-- E05: Comparing null to non-nullable column
badNull :: Query (Flight Expr)
badNull = do
  f <- each flightSchema
  where_ (f.flightNo ==. null)
  pure f
