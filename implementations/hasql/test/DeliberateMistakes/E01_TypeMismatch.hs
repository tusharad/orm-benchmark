module E01_TypeMismatch where

import Data.Int (Int32)
import Data.Text (Text)
import qualified Hasql.Encoders as E
import qualified Hasql.Statement as S
import qualified Hasql.Decoders as D

badStmt :: S.Statement Text Int32
badStmt = S.preparable "SELECT 1 WHERE $1 = 1" (E.param (E.nonNullable E.int4)) (D.singleRow (D.column (D.nonNullable D.int4)))
