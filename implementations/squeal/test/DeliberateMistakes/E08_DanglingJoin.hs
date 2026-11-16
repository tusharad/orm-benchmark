{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE OverloadedStrings #-}

module E08_DanglingJoin where

import Squeal.PostgreSQL
import Schema

-- E08: Referencing an unbound table alias #unjoined_table
badDangling :: Query_ DB () ()
badDangling = select (DotStar #f)
  ( from (table ((#postgres_air ! #flight) `as` #f))
  & where_ (#unjoined_table ! #account_id .== (1 :: Expr ('NotNull 'PGint4)))
  )
