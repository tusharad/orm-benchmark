module E03_MissingGroupBy where
import Database.Persistent.PostgresAir.Schema

-- E03: Non-existent field on Flight
badField :: Flight -> Int
badField f = flightNonExistentField f
