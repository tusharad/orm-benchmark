module E08_DanglingJoin where

import Models

badDangling :: Flight -> Bool
badDangling f = flight_id f == unjoinedAirportId
