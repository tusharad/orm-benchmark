package main

type FlightID int32
type PassengerID int64

func main() {
	var fId FlightID = 101
	var pId PassengerID = 101
	// E02: Cannot compare distinct typed keys FlightID and PassengerID
	_ = fId == pId
}
