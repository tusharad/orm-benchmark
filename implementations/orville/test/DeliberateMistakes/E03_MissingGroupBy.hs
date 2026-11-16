module E03_MissingGroupBy where
import Models

-- E03: Accessing non-existent record field
badField f = flightNonExistentField f
