package main

type ImmutableKey struct {
	key int64
}

func (k ImmutableKey) FlightID() int64 {
	return k.key
}

func main() {
	var k ImmutableKey
	// E09: Cannot assign to unexported field / method
	k.FlightID = 999
}
