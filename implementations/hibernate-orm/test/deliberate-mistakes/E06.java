package org.hibernate.bench.mistakes;

import org.hibernate.bench.models.Flight;

public class E06 {
    public static void test() {
        Flight f = new Flight();
        f.getNonExistentColumn();
    }
}
