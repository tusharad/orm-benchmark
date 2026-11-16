package main

type WherePredicate struct {
	Condition bool
}

func main() {
	var rowNumber int64 = 1
	// E07: Cannot use integer window result as boolean predicate
	_ = WherePredicate{
		Condition: rowNumber,
	}
}
