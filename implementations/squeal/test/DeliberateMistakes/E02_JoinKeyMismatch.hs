{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE OverloadedStrings #-}

module E02_JoinKeyMismatch where

import Squeal.PostgreSQL
import Schema

-- E02: Equating Int32 flight_id with Int64 booking_id without cast
badJoin :: Query_ DB () ()
badJoin = select_ Nil
  ( from (table ((#postgres_air ! #flight) `as` #f)
    & innerJoin (table ((#postgres_air ! #booking) `as` #b))
        (#f ! #flight_id .== #b ! #booking_id)
    )
  )
