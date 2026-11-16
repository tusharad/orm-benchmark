package org.hibernate.bench.mistakes;

import org.hibernate.Session;
import org.hibernate.bench.models.Flight;
import java.util.function.Function;

public class E04 {
    public static void test(Session session) {
        Function<Flight, String> pureFn = f -> {
            System.out.println(f);
        };
    }
}
