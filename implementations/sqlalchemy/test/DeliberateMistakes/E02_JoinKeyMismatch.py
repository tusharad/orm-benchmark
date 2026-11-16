# E02: Foreign Key Type Mismatch in Join Condition
flight_key = 101
passenger_key = "PA-9999"
if type(flight_key) is not type(passenger_key):
    raise TypeError(f"Join key mismatch: Flight.flight_id ({type(flight_key).__name__}) incompatible with Passenger.passenger_id ({type(passenger_key).__name__})")
