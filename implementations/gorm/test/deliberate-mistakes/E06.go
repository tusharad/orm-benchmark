package main

type Flight struct {
	FlightID int32
	FlightNo string
}

func main() {
	var f Flight
	// E06: Field typo flight_noo does not exist
	_ = f.FlightNoo
}
