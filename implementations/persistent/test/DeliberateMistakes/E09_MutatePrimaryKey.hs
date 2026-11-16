module E09_MutatePrimaryKey where
import Database.Persist
import Database.Persistent.PostgresAir.Schema

-- E09: Modifying a Primary Key field which Persistent prohibits
badUpdate :: [Update Flight]
badUpdate = [FlightFlightId =. (99999 :: Int)]
