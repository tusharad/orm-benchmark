// E01: Type Mismatch in Equality / Nullability Comparison
export function badTypeMismatch() {
  const actualDeparture: Date | null = null;
  const bareDate: Date = actualDeparture;
  return bareDate;
}
