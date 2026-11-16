# E02: Foreign Key Type Mismatch in Join Condition
f_id = 101
p_id = "PA-500"
raise TypeError, "type mismatch: FlightId (Integer) vs PassengerId (String)" if f_id.class != p_id.class
