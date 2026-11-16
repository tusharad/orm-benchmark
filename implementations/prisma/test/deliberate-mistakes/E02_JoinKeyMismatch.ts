// E02: Foreign Key Type Mismatch in Join Condition
type FlightId = number & { readonly __brand: unique symbol };
type PassengerId = string & { readonly __brand: unique symbol };

export function badJoin(f: FlightId, p: PassengerId): boolean {
  return f === p;
}
