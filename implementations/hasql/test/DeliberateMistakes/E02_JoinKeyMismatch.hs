module E02_JoinKeyMismatch where

import Data.Int (Int32, Int64)

eqKeys :: Int32 -> Int64 -> Bool
eqKeys fId bId = fId == bId
