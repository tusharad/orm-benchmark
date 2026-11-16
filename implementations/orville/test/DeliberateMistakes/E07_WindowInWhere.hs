module E07_WindowInWhere where
import Models
import qualified Orville.PostgreSQL as O

-- E07: Passing Boolean to integerField
badCond = O.fieldEquals versionField True
