package main

type PureQuery func() string

func main() {
	// E04: Pure function returning int cannot be assigned to PureQuery
	var q PureQuery = func() int {
		return 42
	}
	_ = q
}
