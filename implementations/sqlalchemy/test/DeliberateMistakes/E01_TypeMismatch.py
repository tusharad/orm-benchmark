# E01: Type Mismatch in Equality
flight_id: int = 101
target_code: str = "JFK"
if type(flight_id) is not type(target_code):
    raise TypeError(f"Type mismatch: flight_id ({type(flight_id).__name__}) cannot be compared with airport_code ({type(target_code).__name__})")
