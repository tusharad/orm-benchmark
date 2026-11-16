package org.hibernate.bench.mistakes;

import org.hibernate.Session;
import org.hibernate.bench.models.Flight;
import jakarta.persistence.criteria.*;

public class E10 {
    public static void test(Session session) {
        CriteriaBuilder cb = session.getCriteriaBuilder();
        CriteriaQuery<Flight> cq = cb.createQuery(Flight.class);
        {
            Subquery<Integer> sq = cq.subquery(Integer.class);
            Root<Flight> innerFlight = sq.from(Flight.class);
        }
        cq.where(cb.equal(innerFlight.get("flightId"), 1));
    }
}
