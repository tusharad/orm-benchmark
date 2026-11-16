package org.jooq.bench.mistakes;

import org.jooq.DSLContext;
import static org.jooq.bench.models.Tables.FLIGHT;
import static org.jooq.bench.models.Tables.PASSENGER;

public class E02 {
    public static void test(DSLContext ctx) {
        ctx.select()
           .from(FLIGHT)
           .join(PASSENGER)
           .on(FLIGHT.FLIGHT_ID.eq(PASSENGER.FIRST_NAME))
           .fetch();
    }
}
