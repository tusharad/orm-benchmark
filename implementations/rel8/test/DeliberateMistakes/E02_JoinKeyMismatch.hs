{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}
module E02_JoinKeyMismatch where

import Rel8
import Schema

-- E02: Equating Int32 flight_id with Int64 booking_id
badJoin :: Query (Flight Expr)
badJoin = do
  f <- each flightSchema
  b <- each bookingSchema
  where_ (f.flightId ==. b.bookingId)
  pure f
