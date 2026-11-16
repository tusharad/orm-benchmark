module E08_DanglingJoin where
import Database.Persist
import Database.Persistent.PostgresAir.Schema

-- E08: Using Airport field on Flight
badFilter :: [Filter Flight]
badFilter = [AirportAirportCode ==. "JFK"]
