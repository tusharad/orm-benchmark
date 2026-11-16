{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}
module E07_WindowInWhere where

import Database.Esqueleto.Experimental
import Database.Esqueleto.PostgresAir.Schema

-- E07: Placing window function directly inside where_ expression
badWindowWhere :: SqlQuery (SqlExpr (Entity Flight))
badWindowWhere = do
  f <- from $ table @Flight
  where_ (row_number_ () ==. val 1)
  pure f
