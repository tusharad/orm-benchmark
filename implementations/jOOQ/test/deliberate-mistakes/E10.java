package org.jooq.bench.mistakes;

import org.jooq.DSLContext;
import static org.jooq.bench.models.Tables.FLIGHT;

public class E10 {
    public static void test(DSLContext ctx) {
        {
            var innerQuery = ctx.select(FLIGHT.FLIGHT_ID).from(FLIGHT);
        }
        ctx.select().from(innerQuery).fetch();
    }
}
