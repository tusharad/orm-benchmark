# E09: Mutating Immutable Primary Key in Changeset
record = { flight_id: 101 }.freeze
record[:flight_id] = 999
