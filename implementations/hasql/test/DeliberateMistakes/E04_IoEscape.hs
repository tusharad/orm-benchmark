module E04_IoEscape where

import qualified Hasql.Statement as S
import qualified Hasql.Encoders as E
import qualified Hasql.Decoders as D

badPureStmt :: S.Statement () ()
badPureStmt = do
  putStrLn "Side effect inside pure statement"
  S.preparable "SELECT 1" E.noParams D.noResult
