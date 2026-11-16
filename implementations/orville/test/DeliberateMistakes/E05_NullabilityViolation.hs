module E05_NullabilityViolation where
import Models
import qualified Orville.PostgreSQL as O
import qualified Orville.PostgreSQL.Expr as Expr
import Data.Time (UTCTime)

-- E05: actualDepartureField expects Maybe UTCTime, passing bare UTCTime
badCond :: UTCTime -> Expr.BooleanExpr
badCond t = O.fieldEquals actualDepartureField t
