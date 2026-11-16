package org.jooq.bench.mistakes;

import org.jooq.bench.models.Flight;

public class E06 {
    public static void test() {
        Flight f = new Flight();
        f.getNonExistentColumn();
    }
}
