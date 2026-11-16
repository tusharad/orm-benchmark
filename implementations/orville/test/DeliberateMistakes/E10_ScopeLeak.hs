module E10_ScopeLeak where
import Models
import qualified Orville.PostgreSQL as O

-- E10: Undefined variable in expression
badCond = O.fieldEquals flightIdField undefinedVariableScope
