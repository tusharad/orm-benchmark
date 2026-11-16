module E10_ScopeLeak where
import Database.Persist
import Database.Persistent.PostgresAir.Schema

-- E10: Using an undefined local variable in query
badFilter :: [Filter Flight]
badFilter = [FlightFlightId ==. undefinedKeyVariable]
