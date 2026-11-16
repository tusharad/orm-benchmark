package org.jooq.bench.mistakes;

import org.jooq.bench.models.Flight;
import java.util.List;
import java.util.stream.Collectors;

public class E03 {
    public static void test(List<Flight> flights) {
        flights.stream()
            .collect(Collectors.groupingBy(Flight::getDepartureAirport))
            .forEach((airport, group) -> {
                String no = f.getFlightNo();
            });
    }
}
