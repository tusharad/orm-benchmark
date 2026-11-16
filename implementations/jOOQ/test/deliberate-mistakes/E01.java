package org.jooq.bench.mistakes;

import org.jooq.DSLContext;
import static org.jooq.bench.models.Tables.FLIGHT;

public class E01 {
    public static void test(DSLContext ctx) {
        ctx.selectFrom(FLIGHT)
           .where(FLIGHT.FLIGHT_ID.eq("INVALID_STRING"))
           .fetch();
    }
}
