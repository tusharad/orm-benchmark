{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}
module E09_MutatePrimaryKey where

import Database.Esqueleto.Experimental
import Database.Esqueleto.PostgresAir.Schema

-- E09: Assigning to non-assignable/immutable primary key
badPkUpdate :: SqlQuery ()
badPkUpdate = do
  update $ \a -> do
    set a [ AccountAccountId =. val 999 ]
    where_ (a ^. AccountAccountId ==. val 1)
