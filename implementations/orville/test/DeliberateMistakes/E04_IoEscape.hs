module E04_IoEscape where
import qualified Orville.PostgreSQL as O

-- E04: Pure function trying to escape Orville monad
badEscape :: O.Orville a -> a
badEscape x = x
