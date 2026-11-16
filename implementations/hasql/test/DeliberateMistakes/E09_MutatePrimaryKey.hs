module E09_MutatePrimaryKey where

import Models

badUpdate :: Flight -> Flight
badUpdate f = f { flight_id = "invalid_string_id" }
