package main

import "time"

type Flight struct {
	ActualDeparture *time.Time
}

func main() {
	var f Flight
	var bareTime time.Time
	// E01: Cannot compare *time.Time directly with time.Time without dereference
	_ = f.ActualDeparture == bareTime
}
