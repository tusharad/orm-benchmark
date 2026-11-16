package org.hibernate.bench.mistakes;

import org.hibernate.bench.models.Flight;

public class E05 {
    public static void test() {
        Flight f = new Flight();
        int flightId = null;
        f.setFlightId(flightId);
    }
}
