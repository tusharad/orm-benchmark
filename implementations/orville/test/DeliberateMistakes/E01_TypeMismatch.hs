module E01_TypeMismatch where
import Models
import qualified Orville.PostgreSQL as O

-- E01: Passing Int to Text field
badCond = O.fieldEquals flightNoField (12345 :: Int)
