// E09: Mutating Immutable Primary Key in Changeset
export interface FlightRecord {
  readonly flightId: number;
  status: string;
}

export function badMutation(f: FlightRecord) {
  f.flightId = 999;
}
