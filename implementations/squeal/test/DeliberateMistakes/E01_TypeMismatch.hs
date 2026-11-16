{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE OverloadedStrings #-}

module E01_TypeMismatch where

import Squeal.PostgreSQL
import Schema

-- E01: Comparing integer flight_id to text string
badQuery :: Query_ DB () ()
badQuery = select_ Nil
  ( from (table ((#postgres_air ! #flight) `as` #f))
  & where_ (#f ! #flight_id .== ("invalid_flight_id" :: Expr ('NotNull 'PGtext)))
  )
