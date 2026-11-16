module E08_DanglingJoin where
import Models
import qualified Orville.PostgreSQL as O

-- E08: Incompatible type in where clause
badCond = O.fieldIn flightIdField ["JFK", "LAX"]
