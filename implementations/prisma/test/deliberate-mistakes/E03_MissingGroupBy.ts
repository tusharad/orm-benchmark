// E03: Missing Column in GROUP BY (Ungrouped Column in Projection)
export interface GroupedRow {
  airportCode: string;
  totalFlights: number;
}

export function badGroupBy(row: GroupedRow) {
  return row.departureAirport;
}
