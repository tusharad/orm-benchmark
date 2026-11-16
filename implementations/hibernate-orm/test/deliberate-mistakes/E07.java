package org.hibernate.bench.mistakes;

import org.hibernate.Session;
import org.hibernate.bench.models.Flight;
import jakarta.persistence.criteria.*;

public class E07 {
    public static void test(Session session) {
        CriteriaBuilder cb = session.getCriteriaBuilder();
        CriteriaQuery<Flight> cq = cb.createQuery(Flight.class);
        cq.where(cb.denseRank());
    }
}
