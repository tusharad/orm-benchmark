# E03: Missing Column in GROUP BY Clause
class GroupedFlightSummary:
    def __init__(self, airport_code: str, total_flights: int):
        self.airport_code = airport_code
        self.total_flights = total_flights

summary = GroupedFlightSummary("JFK", 120)
getattr(summary, "departure_airport")
