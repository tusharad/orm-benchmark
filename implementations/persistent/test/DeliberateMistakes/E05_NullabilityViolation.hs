module E05_NullabilityViolation where
import Database.Persist
import Database.Persistent.PostgresAir.Schema
import Data.Time (UTCTime)

-- E05: ActualDeparture is Maybe UTCTime, passing bare UTCTime where Maybe UTCTime required
badFilter :: UTCTime -> [Filter Flight]
badFilter t = [FlightActualDeparture ==. t]
