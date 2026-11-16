// E05: Nullability Violation on Non-Nullable Column
export interface AirportInsert {
  airportCode: string;
  airportName: string;
}

export const badInsert: AirportInsert = {
  airportCode: "JFK",
  airportName: null as any as (null extends string ? never : null),
};
