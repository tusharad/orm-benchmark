package org.hibernate.bench.mistakes;

import org.hibernate.bench.models.FlightSeatInventoryId;

public class E09 {
    public static void test(final FlightSeatInventoryId id) {
        id = new FlightSeatInventoryId(1, "12A");
    }
}
