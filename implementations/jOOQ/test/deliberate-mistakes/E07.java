package org.jooq.bench.mistakes;

import org.jooq.DSLContext;
import static org.jooq.impl.DSL.denseRank;
import static org.jooq.bench.models.Tables.FLIGHT;

public class E07 {
    public static void test(DSLContext ctx) {
        ctx.selectFrom(FLIGHT)
           .where(denseRank())
           .fetch();
    }
}
