module E10_ScopeLeak where

import Data.Int (Int32)
import Models

badScope :: Flight -> Int32
badScope f =
  let _innerVal = flight_id f
  in innerFlightId
