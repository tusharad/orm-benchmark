module E01_TypeMismatch where
import Database.Persist
import Database.Persistent.PostgresAir.Schema

-- E01: Passing Int to Text filter
badFilter :: [Filter Flight]
badFilter = [FlightFlightNo ==. (12345 :: Int)]
