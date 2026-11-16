package main

func main() {
	{
		var innerCte = "active_flights"
		_ = innerCte
	}
	// E10: Inner scope variable leaked to outer scope
	_ = innerCte
}
