package org.jooq.bench.mistakes;

import org.jooq.bench.models.Flight;

public class E05 {
    public static void test() {
        Flight f = new Flight();
        int flightId = null;
        f.setFlightId(flightId);
    }
}
