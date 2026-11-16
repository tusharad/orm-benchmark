# E05: Nullability Violation on Non-Nullable Column
airport_name = nil
raise ArgumentError, "airport_name cannot be nil" if airport_name.nil?
