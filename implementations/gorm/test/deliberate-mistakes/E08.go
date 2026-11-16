package main

type Flight struct {
	FlightID int32
}

func main() {
	var f Flight
	_ = f
	// E08: Unbound reference to unjoined airport table
	_ = unjoinedAirport.AirportName
}
