{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE OverloadedStrings #-}

module E04_IoEscape where

import Squeal.PostgreSQL
import Schema

-- E04: Trying to execute IO inside pure query construction
badIo :: Query_ DB () ()
badIo = do
  putStrLn "Escape IO"
  select (DotStar #f) (from (table ((#postgres_air ! #flight) `as` #f)))
