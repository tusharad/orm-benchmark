module E06_UnknownColumn where

import Data.Int (Int32)
import Models

badField :: Flight -> Int32
badField f = nonExistentColumn f
