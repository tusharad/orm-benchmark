package org.hibernate.bench.mistakes;

import org.hibernate.Session;
import org.hibernate.bench.models.Flight;
import jakarta.persistence.criteria.*;

public class E01 {
    public static void test(Session session) {
        CriteriaBuilder cb = session.getCriteriaBuilder();
        CriteriaQuery<Flight> cq = cb.createQuery(Flight.class);
        Root<Flight> root = cq.from(Flight.class);
        Path<Integer> idPath = root.get("flightId");
        Predicate p = cb.greaterThan(idPath, "INVALID");
        cq.where(p);
    }
}
