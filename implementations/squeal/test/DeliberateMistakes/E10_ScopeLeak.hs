{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE OverloadedStrings #-}

module E10_ScopeLeak where

import Squeal.PostgreSQL
import Schema

-- E10: Outer query accessing inner subquery alias directly outside its scope
badScope :: Query_ DB () ()
badScope = select (DotStar #f)
  ( from (table ((#postgres_air ! #flight) `as` #f))
  & where_ (#subquery_alias ! #flight_id .== (1 :: Expr ('NotNull 'PGint4)))
  )
