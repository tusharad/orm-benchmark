module E09_MutatePrimaryKey where
import Models
import qualified Orville.PostgreSQL as O

-- E09: Comparing primary key with incompatible type
badCond = O.fieldGreaterThan flightIdField ("not-an-id" :: String)
