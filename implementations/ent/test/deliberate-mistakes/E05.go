package main

type Airport struct {
	AirportCode string
	AirportName string
}

func main() {
	// E05: Cannot assign nil to non-nullable string field
	_ = Airport{
		AirportCode: "JFK",
		AirportName: nil,
	}
}
