{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE OverloadedStrings #-}

module E09_MutatePrimaryKey where

import Squeal.PostgreSQL
import Schema

-- E09: Assigning text string to integer primary key
badUpdate :: Manipulation_ DB () ()
badUpdate = update_ (#postgres_air ! #account)
  (Set ("invalid_string_id" :: Expr ('NotNull 'PGtext)) `as` #account_id)
  (#account_id .== (1 :: Expr ('NotNull 'PGint4)))
