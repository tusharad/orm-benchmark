module E06_UnknownColumn where
import Database.Persist
import Database.Persistent.PostgresAir.Schema

-- E06: Unknown column in filter
badFilter :: [Filter Flight]
badFilter = [FlightNoSuchColumn ==. ("test" :: String)]
