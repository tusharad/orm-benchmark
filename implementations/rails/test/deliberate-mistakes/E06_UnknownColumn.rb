# E06: Non-Existent Column Selection (Field Typo)
FlightStruct = Struct.new(:flight_id, :flight_no)
f = FlightStruct.new(101, "FL101")
f.flight_noo
