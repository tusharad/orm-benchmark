{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}
module E06_UnknownColumn where

import Database.Esqueleto.Experimental
import Database.Esqueleto.PostgresAir.Schema

-- E06: Field typo / non-existent record field
badField :: SqlQuery (SqlExpr (Entity Flight))
badField = do
  f <- from $ table @Flight
  where_ (f ^. FlightNonExistentColumn ==. val 1)
  pure f
