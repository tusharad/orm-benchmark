{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}
module E09_MutatePrimaryKey where

import Rel8
import Schema

-- E09: Assigning invalid type to primary key
badPkUpdate :: Update ()
badPkUpdate = Update
  { target = accountSchema
  , from = pure ()
  , set = \_ a -> a { accountId = "invalid_string_id" }
  , updateWhere = \_ a -> a.accountId ==. lit 1
  , returning = pure ()
  }
