package org.jooq.bench.mistakes;

import org.jooq.bench.models.Flight;
import java.util.function.Function;

public class E04 {
    public static void test() {
        Function<Flight, String> pureFn = f -> {
            System.out.println(f);
        };
    }
}
