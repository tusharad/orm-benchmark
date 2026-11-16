# E06: Unknown Column Selection (Field Typo)
class FlightRecord:
    flight_id: int = 101
    flight_no: str = "FL101"

f = FlightRecord()
getattr(f, "flight_noo")
