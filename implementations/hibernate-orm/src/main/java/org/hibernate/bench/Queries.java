package org.hibernate.bench;

import jakarta.persistence.LockModeType;
import jakarta.persistence.Tuple;
import jakarta.persistence.criteria.*;
import org.hibernate.Session;
import org.hibernate.Transaction;
import org.hibernate.bench.models.*;

import java.math.BigDecimal;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.*;

public class Queries {

    // =========================================================================
    // Category I: Large-Scale Hydration, Memory & Deserialization Strain
    // =========================================================================

    // HQ01: Massive Entity Deserialization (10,000 Wide Rows)
    public static List<Flight> hq01MassiveDeserialization(Session session) {
        return session.createQuery("FROM Flight f WHERE f.flightId <= 10000 ORDER BY f.flightId ASC", Flight.class)
                .setMaxResults(10000)
                .setReadOnly(true)
                .list();
    }

    // HQ02: Wide Multi-Join Composite Hydration (5,000 Joined Records)
    public static List<Object[]> hq02WideJoinHydration(Session session) {
        String hql = "SELECT b, p, bl, f FROM Booking b " +
                "JOIN Passenger p ON b.bookingId = p.bookingId " +
                "JOIN BookingLeg bl ON b.bookingId = bl.bookingId " +
                "JOIN Flight f ON bl.flightId = f.flightId " +
                "WHERE b.bookingId BETWEEN 100000 AND 105000";
        return session.createQuery(hql, Object[].class)
                .setMaxResults(5000)
                .setReadOnly(true)
                .list();
    }

    // =========================================================================
    // Category II: Deep Hierarchical Graph Hydration & N+1 Prevention
    // =========================================================================

    public static class FlightGraph {
        public Flight flight;
        public List<Object[]> legs = new ArrayList<>();
        public FlightGraph(Flight flight) { this.flight = flight; }
    }

    // HQ03: 4-Level Deep Hierarchical Entity Tree Materialization
    public static List<FlightGraph> hq03DeepGraphFetch(Session session, int minFid, int maxFid) {
        String hql = "SELECT f, bl, b, bp FROM Flight f " +
                "JOIN BookingLeg bl ON f.flightId = bl.flightId " +
                "JOIN Booking b ON bl.bookingId = b.bookingId " +
                "LEFT JOIN BoardingPass bp ON bl.bookingLegId = bp.bookingLegId " +
                "WHERE f.flightId BETWEEN :minFid AND :maxFid " +
                "ORDER BY f.flightId, bl.bookingLegId";

        List<Object[]> rows = session.createQuery(hql, Object[].class)
                .setParameter("minFid", minFid)
                .setParameter("maxFid", maxFid)
                .setReadOnly(true)
                .list();

        Map<Integer, FlightGraph> map = new LinkedHashMap<>();
        for (Object[] r : rows) {
            Flight f = (Flight) r[0];
            BookingLeg bl = (BookingLeg) r[1];
            Booking b = (Booking) r[2];
            BoardingPass bp = (BoardingPass) r[3];

            FlightGraph fg = map.computeIfAbsent(f.getFlightId(), id -> new FlightGraph(f));
            fg.legs.add(new Object[]{bl, b, bp});
        }
        return new ArrayList<>(map.values());
    }

    public static class AccountGraph {
        public Account account;
        public FrequentFlyer frequentFlyer;
        public List<Object[]> bookings = new ArrayList<>();
        public AccountGraph(Account account, FrequentFlyer frequentFlyer) {
            this.account = account;
            this.frequentFlyer = frequentFlyer;
        }
    }

    // HQ04: Account Relationship Graph with Optional Sub-Entities
    public static List<AccountGraph> hq04AccountGraph(Session session, int minAcc, int maxAcc) {
        String hql = "SELECT a, ff, b, p FROM Account a " +
                "LEFT JOIN FrequentFlyer ff ON a.frequentFlyerId = ff.frequentFlyerId " +
                "LEFT JOIN Booking b ON a.accountId = b.accountId " +
                "LEFT JOIN Passenger p ON b.bookingId = p.bookingId " +
                "WHERE a.accountId BETWEEN :minAcc AND :maxAcc " +
                "ORDER BY a.accountId";

        List<Object[]> rows = session.createQuery(hql, Object[].class)
                .setParameter("minAcc", minAcc)
                .setParameter("maxAcc", maxAcc)
                .setReadOnly(true)
                .list();

        Map<Integer, AccountGraph> map = new LinkedHashMap<>();
        for (Object[] r : rows) {
            Account a = (Account) r[0];
            FrequentFlyer ff = (FrequentFlyer) r[1];
            Booking b = (Booking) r[2];
            Passenger p = (Passenger) r[3];

            AccountGraph ag = map.computeIfAbsent(a.getAccountId(), id -> new AccountGraph(a, ff));
            if (b != null) {
                ag.bookings.add(new Object[]{b, p});
            }
        }
        return new ArrayList<>(map.values());
    }

    // =========================================================================
    // Category III: Multi-Table Analytical Ledgers & Heavy Aggregations
    // =========================================================================

    public record RouteLedger(
            String origin, String destination, String model,
            Long totalFlights, Long totalLegs, Double totalRevenue,
            Double avgDelayMin, Double onTimePct
    ) {}

    // HQ05: Fleet & Route Profitability Analytical Ledger (5 Tables, 400k+ Rows)
    public static List<RouteLedger> hq05RouteLedger(Session session, Instant startTs, Instant endTs) {
        String sql = "SELECT orig.airport_code, dest.airport_code, ac.model, " +
                "       count(DISTINCT f.flight_id)::bigint AS total_flights, " +
                "       count(bl.booking_leg_id)::bigint AS total_legs, " +
                "       round(sum(b.price), 2)::float8 AS total_revenue, " +
                "       round(avg(EXTRACT(EPOCH FROM (f.actual_departure - f.scheduled_departure)) / 60)::numeric, 2)::float8 AS avg_delay_min, " +
                "       round(100.0 * count(CASE WHEN f.actual_departure <= f.scheduled_departure + INTERVAL '15 minutes' THEN 1 END) / count(f.flight_id), 2)::float8 AS on_time_pct " +
                "FROM flight f " +
                "JOIN airport orig ON f.departure_airport = orig.airport_code " +
                "JOIN airport dest ON f.arrival_airport = dest.airport_code " +
                "JOIN aircraft ac ON f.aircraft_code = ac.code " +
                "JOIN booking_leg bl ON f.flight_id = bl.flight_id " +
                "JOIN booking b ON bl.booking_id = b.booking_id " +
                "WHERE f.scheduled_departure >= :startTs AND f.scheduled_departure < :endTs " +
                "GROUP BY orig.airport_code, dest.airport_code, ac.model " +
                "HAVING count(DISTINCT f.flight_id) >= 3 " +
                "ORDER BY total_revenue DESC " +
                "LIMIT 50";

        List<Tuple> list = session.createNativeQuery(sql, Tuple.class)
                .setParameter("startTs", startTs)
                .setParameter("endTs", endTs)
                .setReadOnly(true)
                .list();

        List<RouteLedger> res = new ArrayList<>(list.size());
        for (Tuple t : list) {
            res.add(new RouteLedger(
                    t.get(0, String.class),
                    t.get(1, String.class),
                    t.get(2, String.class),
                    t.get(3, Number.class).longValue(),
                    t.get(4, Number.class).longValue(),
                    t.get(5, Number.class).doubleValue(),
                    t.get(6, Number.class).doubleValue(),
                    t.get(7, Number.class).doubleValue()
            ));
        }
        return res;
    }

    public record HubCentrality(
            String airportCode, String airportName, String city,
            Long departures, Long arrivals, Long destinations, Long fleetDiversity,
            Double avgDepDelay, Double avgArrDelay, Double score
    ) {}

    // HQ06: Chained Multi-Stage CTEs (Hub Centrality & Degree)
    public static List<HubCentrality> hq06HubCentrality(Session session, Instant startTs, Instant endTs) {
        String sql = "WITH flight_volumes AS ( " +
                "    SELECT departure_airport AS airport_code, " +
                "           count(*)::bigint AS departures_count, " +
                "           round(avg(EXTRACT(EPOCH FROM (actual_departure - scheduled_departure)) / 60)::numeric, 2)::float8 AS avg_dep_delay " +
                "    FROM flight " +
                "    WHERE scheduled_departure >= :s1 AND scheduled_departure < :e1 " +
                "      AND actual_departure IS NOT NULL " +
                "    GROUP BY departure_airport " +
                "), " +
                "arrival_volumes AS ( " +
                "    SELECT arrival_airport AS airport_code, " +
                "           count(*)::bigint AS arrivals_count, " +
                "           round(avg(EXTRACT(EPOCH FROM (actual_arrival - scheduled_arrival)) / 60)::numeric, 2)::float8 AS avg_arr_delay " +
                "    FROM flight " +
                "    WHERE scheduled_arrival >= :s2 AND scheduled_arrival < :e2 " +
                "      AND actual_arrival IS NOT NULL " +
                "    GROUP BY arrival_airport " +
                "), " +
                "route_connectivity AS ( " +
                "    SELECT departure_airport AS airport_code, " +
                "           count(DISTINCT arrival_airport)::bigint AS unique_destinations, " +
                "           count(DISTINCT aircraft_code)::bigint AS fleet_diversity " +
                "    FROM flight " +
                "    WHERE scheduled_departure >= :s3 AND scheduled_departure < :e3 " +
                "    GROUP BY departure_airport " +
                ") " +
                "SELECT a.airport_code, a.airport_name, a.city, " +
                "       coalesce(fv.departures_count, 0)::bigint, " +
                "       coalesce(av.arrivals_count, 0)::bigint, " +
                "       coalesce(rc.unique_destinations, 0)::bigint, " +
                "       coalesce(rc.fleet_diversity, 0)::bigint, " +
                "       coalesce(fv.avg_dep_delay, 0)::float8, " +
                "       coalesce(av.avg_arr_delay, 0)::float8, " +
                "       round( " +
                "           ((coalesce(fv.departures_count, 0) + coalesce(av.arrivals_count, 0)) * " +
                "           (1.0 + coalesce(rc.unique_destinations, 0) / 100.0) / " +
                "           (1.0 + greatest(coalesce(fv.avg_dep_delay, 0), 0) / 10.0))::numeric, " +
                "           2 " +
                "       )::float8 AS hub_centrality_score " +
                "FROM airport a " +
                "JOIN flight_volumes fv ON a.airport_code = fv.airport_code " +
                "JOIN arrival_volumes av ON a.airport_code = av.airport_code " +
                "JOIN route_connectivity rc ON a.airport_code = rc.airport_code " +
                "ORDER BY hub_centrality_score DESC " +
                "LIMIT 50";

        List<Tuple> list = session.createNativeQuery(sql, Tuple.class)
                .setParameter("s1", startTs).setParameter("e1", endTs)
                .setParameter("s2", startTs).setParameter("e2", endTs)
                .setParameter("s3", startTs).setParameter("e3", endTs)
                .setReadOnly(true)
                .list();

        List<HubCentrality> res = new ArrayList<>(list.size());
        for (Tuple t : list) {
            res.add(new HubCentrality(
                    t.get(0, String.class),
                    t.get(1, String.class),
                    t.get(2, String.class),
                    t.get(3, Number.class).longValue(),
                    t.get(4, Number.class).longValue(),
                    t.get(5, Number.class).longValue(),
                    t.get(6, Number.class).longValue(),
                    t.get(7, Number.class).doubleValue(),
                    t.get(8, Number.class).doubleValue(),
                    t.get(9, Number.class).doubleValue()
            ));
        }
        return res;
    }

    private static Instant toInstant(Object obj) {
        if (obj == null) return null;
        if (obj instanceof Instant) return (Instant) obj;
        if (obj instanceof Timestamp) return ((Timestamp) obj).toInstant();
        if (obj instanceof java.time.OffsetDateTime) return ((java.time.OffsetDateTime) obj).toInstant();
        return Instant.parse(obj.toString());
    }

    public record CapacityRiskFlight(
            Integer flightId, String flightNo, String depAirport, String arrAirport,
            Instant scheduledDep, String aircraftModel, Long seatsBooked, Long eliteFlyers
    ) {}

    // HQ07: Correlated At-Capacity Subquery with Loyalty Tier Cross-Check
    public static List<CapacityRiskFlight> hq07CapacityRiskFlights(Session session, Instant startTs, Instant endTs) {
        String sql = "SELECT f.flight_id, f.flight_no, f.departure_airport, f.arrival_airport, " +
                "       f.scheduled_departure, coalesce(ac.model, 'Unknown'), " +
                "       (SELECT count(*)::bigint FROM booking_leg bl WHERE bl.flight_id = f.flight_id) AS seats_booked, " +
                "       (SELECT count(*)::bigint FROM booking_leg bl " +
                "        JOIN passenger p ON bl.booking_id = p.booking_id " +
                "        JOIN account a ON p.account_id = a.account_id " +
                "        JOIN frequent_flyer ff ON a.frequent_flyer_id = ff.frequent_flyer_id " +
                "        WHERE bl.flight_id = f.flight_id AND ff.level >= 3) AS elite_flyer_count " +
                "FROM flight f " +
                "JOIN aircraft ac ON f.aircraft_code = ac.code " +
                "WHERE f.scheduled_departure >= :startTs AND f.scheduled_departure < :endTs " +
                "  AND ac.class >= 2 " +
                "  AND (SELECT count(*) FROM booking_leg bl WHERE bl.flight_id = f.flight_id) > 40 " +
                "  AND EXISTS ( " +
                "      SELECT 1 FROM flight_seat_inventory fsi " +
                "      WHERE fsi.flight_id = f.flight_id AND fsi.status = 'AVAILABLE' " +
                "  ) " +
                "ORDER BY seats_booked DESC " +
                "LIMIT 50";

        List<Tuple> list = session.createNativeQuery(sql, Tuple.class)
                .setParameter("startTs", startTs)
                .setParameter("endTs", endTs)
                .setReadOnly(true)
                .list();

        List<CapacityRiskFlight> res = new ArrayList<>(list.size());
        for (Tuple t : list) {
            res.add(new CapacityRiskFlight(
                    t.get(0, Integer.class),
                    t.get(1, String.class),
                    t.get(2, String.class),
                    t.get(3, String.class),
                    toInstant(t.get(4)),
                    t.get(5, String.class),
                    t.get(6, Number.class).longValue(),
                    t.get(7, Number.class).longValue()
            ));
        }
        return res;
    }

    public record ConnectingRoute(
            Integer hops, String path, Instant journeyStart, Instant journeyEnd,
            Double elapsedMinutes, Double flightMinutes
    ) {}

    // HQ08: Recursive Multi-Hop Flight Connection Graph Search
    public static List<ConnectingRoute> hq08RecursiveRouteSearch(Session session, String origin, String dest, Instant startTs, Instant endTs) {
        String sql = "WITH RECURSIVE flight_paths AS ( " +
                "    SELECT f.flight_id, f.departure_airport::text AS departure_airport, " +
                "           f.arrival_airport::text AS arrival_airport, " +
                "           f.scheduled_departure, f.scheduled_arrival, 1 AS hops, " +
                "           ARRAY[f.departure_airport::text, f.arrival_airport::text] AS route_airports, " +
                "           ARRAY[f.flight_id] AS route_flights, " +
                "           f.scheduled_departure AS journey_start, f.scheduled_arrival AS journey_end, " +
                "           (EXTRACT(EPOCH FROM (f.scheduled_arrival - f.scheduled_departure)) / 60)::float8 AS total_flight_minutes " +
                "    FROM flight f " +
                "    WHERE f.departure_airport = :origin AND f.scheduled_departure >= :startTs AND f.scheduled_departure < :endTs " +
                "    UNION ALL " +
                "    SELECT next_f.flight_id, fp.departure_airport, next_f.arrival_airport::text, " +
                "           next_f.scheduled_departure, next_f.scheduled_arrival, fp.hops + 1, " +
                "           fp.route_airports || next_f.arrival_airport::text, " +
                "           fp.route_flights || next_f.flight_id, " +
                "           fp.journey_start, next_f.scheduled_arrival, " +
                "           fp.total_flight_minutes + (EXTRACT(EPOCH FROM (next_f.scheduled_arrival - next_f.scheduled_departure)) / 60)::float8 " +
                "    FROM flight_paths fp " +
                "    JOIN flight next_f ON fp.arrival_airport = next_f.departure_airport " +
                "    WHERE fp.hops < 3 " +
                "      AND next_f.scheduled_departure >= fp.scheduled_arrival + INTERVAL '60 minutes' " +
                "      AND next_f.scheduled_departure <= fp.scheduled_arrival + INTERVAL '360 minutes' " +
                "      AND NOT (next_f.arrival_airport::text = ANY(fp.route_airports)) " +
                ") " +
                "SELECT hops, array_to_string(route_airports, ' -> '), journey_start, journey_end, " +
                "       (EXTRACT(EPOCH FROM (journey_end - journey_start)) / 60)::float8 AS total_elapsed_minutes, " +
                "       total_flight_minutes " +
                "FROM flight_paths " +
                "WHERE arrival_airport = :dest " +
                "ORDER BY hops ASC, total_elapsed_minutes ASC " +
                "LIMIT 25";

        List<Tuple> list = session.createNativeQuery(sql, Tuple.class)
                .setParameter("origin", origin)
                .setParameter("dest", dest)
                .setParameter("startTs", startTs)
                .setParameter("endTs", endTs)
                .setReadOnly(true)
                .list();

        List<ConnectingRoute> res = new ArrayList<>(list.size());
        for (Tuple t : list) {
            res.add(new ConnectingRoute(
                    t.get(0, Number.class).intValue(),
                    t.get(1, String.class),
                    toInstant(t.get(2)),
                    toInstant(t.get(3)),
                    t.get(4, Number.class).doubleValue(),
                    t.get(5, Number.class).doubleValue()
            ));
        }
        return res;
    }

    public record DelayWindowAnalytics(
            Integer flightId, String flightNo, String arrAirport, Instant scheduledDep,
            Double delayMin, Double rollingAvg5, Double delayDiffPrev, Double rollingStdDev10, Long severityRank
    ) {}

    // HQ09: Multi-Window Statistical Delay Dispersion & Cascades
    public static List<DelayWindowAnalytics> hq09MultiWindowDelay(Session session, String airport, Instant startTs, Instant endTs) {
        String sql = "WITH flight_delays AS ( " +
                "    SELECT flight_id, flight_no, departure_airport, arrival_airport, " +
                "           scheduled_departure, actual_departure, " +
                "           round((EXTRACT(EPOCH FROM (actual_departure - scheduled_departure)) / 60)::numeric, 2)::float8 AS delay_minutes " +
                "    FROM flight " +
                "    WHERE departure_airport = :airport AND actual_departure IS NOT NULL " +
                "      AND scheduled_departure >= :startTs AND scheduled_departure < :endTs " +
                ") " +
                "SELECT flight_id, flight_no, arrival_airport, scheduled_departure, delay_minutes, " +
                "       round(avg(delay_minutes) OVER ( " +
                "           PARTITION BY departure_airport, arrival_airport " +
                "           ORDER BY scheduled_departure " +
                "           ROWS BETWEEN 4 PRECEDING AND CURRENT ROW " +
                "       )::numeric, 2)::float8 AS rolling_avg_delay_5, " +
                "       (delay_minutes - lag(delay_minutes, 1) OVER ( " +
                "           PARTITION BY departure_airport, arrival_airport " +
                "           ORDER BY scheduled_departure " +
                "       ))::float8 AS delay_diff_prev, " +
                "       round(coalesce(stddev_samp(delay_minutes) OVER ( " +
                "           PARTITION BY departure_airport, arrival_airport " +
                "           ORDER BY scheduled_departure " +
                "           ROWS BETWEEN 9 PRECEDING AND CURRENT ROW " +
                "       ), 0)::numeric, 2)::float8 AS rolling_stddev_10, " +
                "       dense_rank() OVER ( " +
                "           PARTITION BY departure_airport, arrival_airport " +
                "           ORDER BY delay_minutes DESC " +
                "       )::bigint AS severity_rank " +
                "FROM flight_delays " +
                "ORDER BY departure_airport, arrival_airport, scheduled_departure " +
                "LIMIT 5000";

        List<Tuple> list = session.createNativeQuery(sql, Tuple.class)
                .setParameter("airport", airport)
                .setParameter("startTs", startTs)
                .setParameter("endTs", endTs)
                .setReadOnly(true)
                .list();

        List<DelayWindowAnalytics> res = new ArrayList<>(list.size());
        for (Tuple t : list) {
            Number diff = t.get(6, Number.class);
            res.add(new DelayWindowAnalytics(
                    t.get(0, Integer.class),
                    t.get(1, String.class),
                    t.get(2, String.class),
                    toInstant(t.get(3)),
                    t.get(4, Number.class).doubleValue(),
                    t.get(5, Number.class).doubleValue(),
                    diff != null ? diff.doubleValue() : null,
                    t.get(7, Number.class).doubleValue(),
                    t.get(8, Number.class).longValue()
            ));
        }
        return res;
    }

    // HQ10: Keyset (Cursor) Pagination over Composite Tuple Under Concurrency
    public static List<Flight> hq10KeysetPagination(Session session, Instant cursorTs, int cursorId, int limit) {
        String hql = "FROM Flight f WHERE f.scheduledDeparture > :cTime OR " +
                "(f.scheduledDeparture = :cTime AND f.flightId > :cId) " +
                "ORDER BY f.scheduledDeparture ASC, f.flightId ASC";

        return session.createQuery(hql, Flight.class)
                .setParameter("cTime", cursorTs)
                .setParameter("cId", cursorId)
                .setMaxResults(limit)
                .setReadOnly(true)
                .list();
    }

    // =========================================================================
    // Category V: Dynamic Query Composition & Bulk Ingestion
    // =========================================================================

    public static class FlightSearchParams {
        public List<String> origins;
        public List<String> destinations;
        public Instant minDeparture;
        public Instant maxDeparture;
        public List<Integer> aircraftClass;
        public BigDecimal minRange;
        public List<String> statuses;
        public Instant cursorTime;
        public Integer cursorId;
        public int limit = 100;
    }

    // HQ11: High-Dimensional Dynamic Faceted Flight Search Engine (10 Optional Predicates)
    public static List<Flight> hq11DynamicFacetedSearch(Session session, FlightSearchParams params) {
        CriteriaBuilder cb = session.getCriteriaBuilder();
        CriteriaQuery<Flight> cq = cb.createQuery(Flight.class);
        Root<Flight> flight = cq.from(Flight.class);
        Join<Flight, Aircraft> aircraft = flight.join("aircraft");

        List<Predicate> predicates = new ArrayList<>();

        if (params.origins != null && !params.origins.isEmpty()) {
            predicates.add(flight.get("departureAirport").in(params.origins));
        }
        if (params.destinations != null && !params.destinations.isEmpty()) {
            predicates.add(flight.get("arrivalAirport").in(params.destinations));
        }
        if (params.minDeparture != null) {
            predicates.add(cb.greaterThanOrEqualTo(flight.get("scheduledDeparture"), params.minDeparture));
        }
        if (params.maxDeparture != null) {
            predicates.add(cb.lessThanOrEqualTo(flight.get("scheduledDeparture"), params.maxDeparture));
        }
        if (params.aircraftClass != null && !params.aircraftClass.isEmpty()) {
            predicates.add(aircraft.get("aircraftClass").in(params.aircraftClass));
        }
        if (params.minRange != null) {
            predicates.add(cb.greaterThanOrEqualTo(aircraft.get("range"), params.minRange));
        }
        if (params.statuses != null && !params.statuses.isEmpty()) {
            predicates.add(flight.get("status").in(params.statuses));
        }
        if (params.cursorTime != null && params.cursorId != null) {
            Predicate p1 = cb.greaterThan(flight.get("scheduledDeparture"), params.cursorTime);
            Predicate p2 = cb.and(
                    cb.equal(flight.get("scheduledDeparture"), params.cursorTime),
                    cb.greaterThan(flight.get("flightId"), params.cursorId)
            );
            predicates.add(cb.or(p1, p2));
        }

        cq.where(predicates.toArray(new Predicate[0]));
        cq.orderBy(cb.asc(flight.get("scheduledDeparture")), cb.asc(flight.get("flightId")));

        return session.createQuery(cq)
                .setMaxResults(params.limit)
                .setReadOnly(true)
                .list();
    }

    // HQ12: High-Volume Batch Upsert (2,500 Records with Conflict Resolution)
    public static int hq12BatchUpsert(Session session, List<FlightStatusUpdate> batch) {
        final int[] updated = {0};
        session.doWork(connection -> {
            String sql = "INSERT INTO postgres_air.flight_status_update (flight_id, status, actual_departure, actual_arrival, update_ts, version) " +
                    "VALUES (?, ?, ?, ?, ?, ?) " +
                    "ON CONFLICT (flight_id) DO UPDATE SET " +
                    "  status = EXCLUDED.status, " +
                    "  actual_departure = EXCLUDED.actual_departure, " +
                    "  actual_arrival = EXCLUDED.actual_arrival, " +
                    "  update_ts = EXCLUDED.update_ts, " +
                    "  version = postgres_air.flight_status_update.version + 1";

            try (PreparedStatement ps = connection.prepareStatement(sql)) {
                for (FlightStatusUpdate u : batch) {
                    ps.setInt(1, u.getFlightId());
                    ps.setString(2, u.getStatus());
                    ps.setTimestamp(3, u.getActualDeparture() != null ? Timestamp.from(u.getActualDeparture()) : null);
                    ps.setTimestamp(4, u.getActualArrival() != null ? Timestamp.from(u.getActualArrival()) : null);
                    ps.setTimestamp(5, u.getUpdateTs() != null ? Timestamp.from(u.getUpdateTs()) : null);
                    ps.setInt(6, u.getVersion());
                    ps.addBatch();
                }
                int[] counts = ps.executeBatch();
                updated[0] = counts.length;
            }
        });
        return updated[0];
    }

    // HQ13: Optimistic Concurrency Bulk Fare & Status Adjustment
    public static int hq13OptimisticBulkUpdate(Session session, int minFid, int maxFid, int expectedVer, String newStatus) {
        Transaction tx = session.beginTransaction();
        try {
            String sql = "UPDATE postgres_air.flight SET status = :newStatus, version = version + 1, update_ts = clock_timestamp() " +
                    "WHERE flight_id BETWEEN :minFid AND :maxFid AND version = :expectedVer";
            int rows = session.createNativeMutationQuery(sql)
                    .setParameter("newStatus", newStatus)
                    .setParameter("minFid", minFid)
                    .setParameter("maxFid", maxFid)
                    .setParameter("expectedVer", expectedVer)
                    .executeUpdate();
            tx.commit();
            return rows;
        } catch (Exception e) {
            tx.rollback();
            throw e;
        }
    }

    // =========================================================================
    // Category VI: Concurrency Contention, Transactions & Multi-Modal Search
    // =========================================================================

    // HQ14: High-Concurrency Seat Allocation Under Contention (C=100)
    public static String hq14ReserveSeatConcurrent(Session session, int flightId, String passengerName) {
        Transaction tx = session.beginTransaction();
        try {
            String sql = "SELECT seat_no, version FROM postgres_air.flight_seat_inventory " +
                    "WHERE flight_id = :fltId AND status = 'AVAILABLE' LIMIT 1 FOR UPDATE";
            List<Tuple> list = session.createNativeQuery(sql, Tuple.class)
                    .setParameter("fltId", flightId)
                    .list();

            if (list.isEmpty()) {
                tx.rollback();
                return "Sold Out";
            }

            Tuple t = list.get(0);
            String seatNo = t.get(0, String.class);
            int ver = t.get(1, Number.class).intValue();

            String updateSql = "UPDATE postgres_air.flight_seat_inventory " +
                    "SET status = 'RESERVED', passenger_name = :pName, reserved_at = clock_timestamp(), version = version + 1 " +
                    "WHERE flight_id = :fltId AND seat_no = :seatNo AND version = :ver";
            session.createNativeMutationQuery(updateSql)
                    .setParameter("pName", passengerName)
                    .setParameter("fltId", flightId)
                    .setParameter("seatNo", seatNo)
                    .setParameter("ver", ver)
                    .executeUpdate();

            tx.commit();
            return seatNo;
        } catch (Exception e) {
            tx.rollback();
            throw e;
        }
    }

    // HQ15: Distributed Financial / Points Transfer with Serialization Retry
    public static void hq15PointsTransferSerializable(Session session, int fromAcc, int toAcc, int points) throws Exception {
        int maxRetries = 5;
        for (int attempt = 0; attempt < maxRetries; attempt++) {
            Transaction tx = session.beginTransaction();
            try {
                session.createNativeQuery("SET TRANSACTION ISOLATION LEVEL SERIALIZABLE").executeUpdate();

                FrequentFlyer sender = session.get(FrequentFlyer.class, fromAcc);
                FrequentFlyer receiver = session.get(FrequentFlyer.class, toAcc);

                if (sender != null && receiver != null) {
                    sender.setAwardPoints(sender.getAwardPoints() - points);
                    receiver.setAwardPoints(receiver.getAwardPoints() + points);
                    session.merge(sender);
                    session.merge(receiver);
                }

                tx.commit();
                return;
            } catch (Exception e) {
                tx.rollback();
                SQLException sqlEx = findSqlException(e);
                if (sqlEx != null && "40001".equals(sqlEx.getSQLState()) && attempt < maxRetries - 1) {
                    Thread.sleep(10L * (1L << attempt));
                    continue;
                }
                throw e;
            }
        }
        throw new RuntimeException("Serialization failure retry limit exceeded");
    }

    private static SQLException findSqlException(Throwable t) {
        while (t != null) {
            if (t instanceof SQLException) return (SQLException) t;
            t = t.getCause();
        }
        return null;
    }

    public record HybridSearchResult(
            String airportCode, String airportName, String city, Long activeFlights, Double rrfScore
    ) {}

    // HQ16: Multi-Modal Hybrid Vector Similarity + BM25 Full-Text Search with RRF Reranking
    public static List<HybridSearchResult> hq16HybridSearchRRF(Session session, String targetAirport, String queryText) {
        String sql = "WITH text_ranking AS ( " +
                "    SELECT airport_code, " +
                "           ROW_NUMBER() OVER (ORDER BY ts_rank_cd(search_tsv, plainto_tsquery('english', :qText)) DESC) AS rank_text " +
                "    FROM airport " +
                "    WHERE search_tsv @@ plainto_tsquery('english', :qText) " +
                "    LIMIT 25 " +
                "), " +
                "vector_ranking AS ( " +
                "    SELECT airport_code, " +
                "           ROW_NUMBER() OVER (ORDER BY (embedding <=> (SELECT embedding FROM airport WHERE airport_code = :targetAirport)) ASC) AS rank_vec " +
                "    FROM airport " +
                "    LIMIT 25 " +
                "), " +
                "airport_stats AS ( " +
                "    SELECT departure_airport AS airport_code, " +
                "           count(*)::bigint AS active_flights_count " +
                "    FROM flight " +
                "    WHERE scheduled_departure >= '2024-07-01' AND scheduled_departure < '2024-07-15' " +
                "    GROUP BY departure_airport " +
                "), " +
                "rrf_scores AS ( " +
                "    SELECT coalesce(t.airport_code, v.airport_code) AS airport_code, " +
                "           (coalesce(1.0 / (60.0 + t.rank_text), 0.0) + coalesce(1.0 / (60.0 + v.rank_vec), 0.0))::float8 AS rrf_score " +
                "    FROM text_ranking t " +
                "    FULL OUTER JOIN vector_ranking v ON t.airport_code = v.airport_code " +
                ") " +
                "SELECT a.airport_code, a.airport_name, a.city, " +
                "       coalesce(s.active_flights_count, 0)::bigint, " +
                "       round(r.rrf_score::numeric, 6)::float8 AS final_rrf_score " +
                "FROM rrf_scores r " +
                "JOIN airport a ON r.airport_code = a.airport_code " +
                "LEFT JOIN airport_stats s ON a.airport_code = s.airport_code " +
                "ORDER BY final_rrf_score DESC " +
                "LIMIT 10";

        List<Tuple> list = session.createNativeQuery(sql, Tuple.class)
                .setParameter("qText", queryText)
                .setParameter("targetAirport", targetAirport)
                .setReadOnly(true)
                .list();

        List<HybridSearchResult> res = new ArrayList<>(list.size());
        for (Tuple t : list) {
            res.add(new HybridSearchResult(
                    t.get(0, String.class),
                    t.get(1, String.class),
                    t.get(2, String.class),
                    t.get(3, Number.class).longValue(),
                    t.get(4, Number.class).doubleValue()
            ));
        }
        return res;
    }
}
