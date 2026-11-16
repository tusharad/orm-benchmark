# E01: Type Mismatch in Equality / Nullability Comparison
actual_departure = nil
raise TypeError, "no implicit conversion of nil into Time" unless actual_departure.is_a?(Time)
