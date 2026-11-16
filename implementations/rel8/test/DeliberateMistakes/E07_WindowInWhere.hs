{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}
module E07_WindowInWhere where

import Rel8
import Schema

-- E07: Placing window function directly inside where_ expression
badWindow :: Query (Flight Expr)
badWindow = do
  f <- each flightSchema
  where_ (rowNumber ==. lit 1)
  pure f
