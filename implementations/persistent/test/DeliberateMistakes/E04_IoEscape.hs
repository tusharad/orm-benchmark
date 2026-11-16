module E04_IoEscape where
import Database.Persist.Sql

-- E04: Pure function trying to run SqlPersistM directly without runSqlPool
badEscape :: SqlPersistM a -> a
badEscape x = x
