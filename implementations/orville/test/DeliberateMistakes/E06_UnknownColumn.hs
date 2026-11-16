module E06_UnknownColumn where
import Models
import qualified Orville.PostgreSQL as O

-- E06: Unknown field
badCond = O.fieldEquals flightNoSuchField "test"
