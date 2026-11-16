// E08: Dangling or Unbound Table Reference
export function badUnboundJoin() {
  const flight = { flightId: 101, flightNo: "FL101" };
  return unjoinedAirport.airportName;
}
