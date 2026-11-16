module E02_JoinKeyMismatch where
import Database.Persist
import Database.Persistent.PostgresAir.Schema
import Data.Int (Int64)

-- E02: FlightId is Int32, comparing with Int64
badFilter :: [Filter Flight]
badFilter = [FlightFlightId ==. (100 :: Int64)]
