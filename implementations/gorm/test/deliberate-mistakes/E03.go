package main

type GroupedAirport struct {
	AirportCode  string
	TotalFlights int64
}

func main() {
	var g GroupedAirport
	// E03: Cannot access DepartureAirport from GroupedAirport
	_ = g.DepartureAirport
}
