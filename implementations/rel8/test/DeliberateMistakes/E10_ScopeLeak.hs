{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}
module E10_ScopeLeak where

import Rel8
import Schema

-- E10: Inner query scope alias leakage
badScope :: Query (Flight Expr)
badScope = do
  let innerQuery = do
        innerFlight <- each flightSchema
        pure innerFlight.flightId
  f <- each flightSchema
  where_ (f.flightId ==. innerFlight.flightId)
  pure f
