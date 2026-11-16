{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE OverloadedStrings #-}

module E07_WindowInWhere where

import Squeal.PostgreSQL
import Schema

-- E07: Placing window function directly inside where_ clause
badWindow :: Query_ DB () ()
badWindow = select (DotStar #f)
  ( from (table ((#postgres_air ! #flight) `as` #f))
  & where_ (rowNumber .== (1 :: Expr ('NotNull 'PGint8)))
  )
