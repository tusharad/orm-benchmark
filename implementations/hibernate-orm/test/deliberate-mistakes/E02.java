package org.hibernate.bench.mistakes;

import org.hibernate.Session;
import org.hibernate.bench.models.*;
import jakarta.persistence.criteria.*;

public class E02 {
    public static void test(Session session) {
        CriteriaBuilder cb = session.getCriteriaBuilder();
        CriteriaQuery<Object[]> cq = cb.createQuery(Object[].class);
        Root<Flight> f = cq.from(Flight.class);
        Root<Passenger> p = cq.from(Passenger.class);
        Path<Integer> fId = f.get("flightId");
        Path<String> pName = p.get("firstName");
        Predicate joinCond = cb.greaterThan(fId, pName);
        cq.where(joinCond);
    }
}
