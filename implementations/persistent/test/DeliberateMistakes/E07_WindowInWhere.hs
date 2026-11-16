module E07_WindowInWhere where
import Database.Persist
import Database.Persistent.PostgresAir.Schema

-- E07: Type error assigning Bool to Int field in Update
badUpdate :: [Update Flight]
badUpdate = [FlightVersion =. True]
