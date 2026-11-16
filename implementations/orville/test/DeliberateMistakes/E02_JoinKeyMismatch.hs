module E02_JoinKeyMismatch where
import Models
import qualified Orville.PostgreSQL as O
import Data.Int (Int64)

-- E02: flightIdField is Int32, passing Int64
badCond = O.fieldEquals flightIdField (100 :: Int64)
