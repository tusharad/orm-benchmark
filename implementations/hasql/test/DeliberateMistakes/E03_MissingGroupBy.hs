module E03_MissingGroupBy where

import Data.Int (Int32)
import Models

badProjection :: Flight -> Int32
badProjection f = departure_airport f
