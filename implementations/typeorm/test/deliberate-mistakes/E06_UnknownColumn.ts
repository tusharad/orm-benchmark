// E06: Non-Existent Column Selection (Field Typo)
export interface FlightModel {
  flightId: number;
  flightNo: string;
}

export function badField(f: FlightModel) {
  return f.flightNoo;
}
