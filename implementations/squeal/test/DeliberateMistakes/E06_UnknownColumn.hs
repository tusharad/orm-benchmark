{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE OverloadedStrings #-}

module E06_UnknownColumn where

import Squeal.PostgreSQL
import Schema

-- E06: Referencing non-existent column on table
badColumn :: Query_ DB () ()
badColumn = select (DotStar #f)
  ( from (table ((#postgres_air ! #flight) `as` #f))
  & where_ (#f ! #non_existent_column .== (1 :: Expr ('NotNull 'PGint4)))
  )
