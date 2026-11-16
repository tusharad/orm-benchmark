# E03: Missing Column in GROUP BY (Ungrouped Column in Projection)
GroupedRow = Struct.new(:airport_code, :total_flights)
row = GroupedRow.new("JFK", 100)
row.departure_airport
