# E05: Nullability Constraint Violation on Non-Nullable Column
flight_no = None
if flight_no is None:
    raise ValueError("Nullability violation: Flight.flight_no is NOT NULL")
