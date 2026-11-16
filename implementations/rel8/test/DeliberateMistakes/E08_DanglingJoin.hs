{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}
module E08_DanglingJoin where

import Rel8
import Schema

-- E08: Referencing an unbound table alias
badDangling :: Query (Expr Bool)
badDangling = do
  f <- each flightSchema
  pure (f.flightId ==. unjoinedAccount.accountId)
