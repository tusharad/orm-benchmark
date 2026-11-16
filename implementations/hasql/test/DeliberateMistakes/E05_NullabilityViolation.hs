module E05_NullabilityViolation where

import Models

badAssign :: Flight -> Flight
badAssign f = f { flight_no = Nothing }
