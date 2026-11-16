package org.jooq.bench;

import org.jooq.*;
import org.jooq.Record;
import org.jooq.impl.DSL;
import org.jooq.bench.models.Flight;
import org.jooq.bench.models.FlightStatusUpdate;
import org.jooq.bench.models.Tables;

import java.math.BigDecimal;
import java.sql.SQLException;
import java.time.Instant;
import java.util.*;

import static org.jooq.impl.DSL.*;
import static org.jooq.bench.models.Tables.*;

public class Queries {

    // =========================================================================
    // Category I: Large-Scale Hydration, Memory & Deserialization Strain
    // =========================================================================

    // HQ01: Massive Entity Deserialization (10,000 Wide Rows)
    public static List<Flight> hq01MassiveDeserialization(DSLContext ctx) {
        return ctx.selectFrom(FLIGHT)
                .where(FLIGHT.FLIGHT_ID.le(10000))
                .orderBy(FLIGHT.FLIGHT_ID.asc())
                .limit(10000)
                .fetch(r -> new Flight(
                        r.get(FLIGHT.FLIGHT_ID),
                        r.get(FLIGHT.FLIGHT_NO),
                        r.get(FLIGHT.SCHEDULED_DEPARTURE),
                        r.get(FLIGHT.SCHEDULED_ARRIVAL),
                        r.get(FLIGHT.DEPARTURE_AIRPORT),
                        r.get(FLIGHT.ARRIVAL_AIRPORT),
                        r.get(FLIGHT.STATUS),
                        r.get(FLIGHT.AIRCRAFT_CODE),
                        r.get(FLIGHT.ACTUAL_DEPARTURE),
                        r.get(FLIGHT.ACTUAL_ARRIVAL),
                        r.get(FLIGHT.UPDATE_TS),
                        r.get(FLIGHT.VERSION)
                ));
    }

    // HQ02: Wide Multi-Join Composite Hydration (5,000 Joined Records)
    public static List<? extends Record> hq02WideJoinHydration(DSLContext ctx) {
        return ctx.select(
                BOOKING.BOOKING_ID, BOOKING.BOOKING_REF, BOOKING.BOOKING_NAME, BOOKING.PRICE,
                PASSENGER.PASSENGER_ID, PASSENGER.FIRST_NAME, PASSENGER.LAST_NAME,
                BOOKING_LEG.BOOKING_LEG_ID, BOOKING_LEG.LEG_NUM,
                FLIGHT.FLIGHT_ID, FLIGHT.FLIGHT_NO, FLIGHT.SCHEDULED_DEPARTURE, FLIGHT.DEPARTURE_AIRPORT, FLIGHT.ARRIVAL_AIRPORT
        )
        .from(BOOKING)
        .join(PASSENGER).on(BOOKING.BOOKING_ID.eq(PASSENGER.BOOKING_ID))
        .join(BOOKING_LEG).on(BOOKING.BOOKING_ID.eq(BOOKING_LEG.BOOKING_ID))
        .join(FLIGHT).on(BOOKING_LEG.FLIGHT_ID.eq(FLIGHT.FLIGHT_ID))
        .where(BOOKING.BOOKING_ID.between(100000L, 105000L))
        .limit(5000)
        .fetch();
    }

    // =========================================================================
    // Category II: Deep Hierarchical Graph Hydration & N+1 Prevention
    // =========================================================================

    public static class FlightGraph {
        public Integer flightId;
        public String flightNo;
        public List<LegGraph> legs = new ArrayList<>();
        public FlightGraph(Integer flightId, String flightNo) {
            this.flightId = flightId;
            this.flightNo = flightNo;
        }
    }

    public static class LegGraph {
        public Integer legId;
        public Long bookingId;
        public String bookingRef;
        public Integer passId;
        public String seat;
        public LegGraph(Integer legId, Long bookingId, String bookingRef, Integer passId, String seat) {
            this.legId = legId;
            this.bookingId = bookingId;
            this.bookingRef = bookingRef;
            this.passId = passId;
            this.seat = seat;
        }
    }

    // HQ03: 4-Level Deep Hierarchical Entity Tree Materialization
    public static List<FlightGraph> hq03DeepGraphFetch(DSLContext ctx, int minFid, int maxFid) {
        var records = ctx.select(
                FLIGHT.FLIGHT_ID, FLIGHT.FLIGHT_NO,
                BOOKING_LEG.BOOKING_LEG_ID,
                BOOKING.BOOKING_ID, BOOKING.BOOKING_REF,
                BOARDING_PASS.PASS_ID, BOARDING_PASS.SEAT
        )
        .from(FLIGHT)
        .join(BOOKING_LEG).on(FLIGHT.FLIGHT_ID.eq(BOOKING_LEG.FLIGHT_ID))
        .join(BOOKING).on(BOOKING_LEG.BOOKING_ID.eq(BOOKING.BOOKING_ID))
        .leftJoin(BOARDING_PASS).on(BOOKING_LEG.BOOKING_LEG_ID.cast(Long.class).eq(BOARDING_PASS.BOOKING_LEG_ID))
        .where(FLIGHT.FLIGHT_ID.between(minFid, maxFid))
        .orderBy(FLIGHT.FLIGHT_ID.asc(), BOOKING_LEG.BOOKING_LEG_ID.asc())
        .fetch();

        Map<Integer, FlightGraph> map = new LinkedHashMap<>();
        for (Record r : records) {
            Integer fId = r.get(FLIGHT.FLIGHT_ID);
            FlightGraph fg = map.computeIfAbsent(fId, id -> new FlightGraph(fId, r.get(FLIGHT.FLIGHT_NO)));
            fg.legs.add(new LegGraph(
                r.get(BOOKING_LEG.BOOKING_LEG_ID),
                r.get(BOOKING.BOOKING_ID),
                r.get(BOOKING.BOOKING_REF),
                r.get(BOARDING_PASS.PASS_ID),
                r.get(BOARDING_PASS.SEAT)
            ));
        }
        return new ArrayList<>(map.values());
    }

    public static class AccountGraph {
        public Integer accountId;
        public String login;
        public Integer frequentFlyerId;
        public Integer points;
        public List<BookingPassenger> bookings = new ArrayList<>();
        public AccountGraph(Integer accountId, String login, Integer frequentFlyerId, Integer points) {
            this.accountId = accountId;
            this.login = login;
            this.frequentFlyerId = frequentFlyerId;
            this.points = points;
        }
    }

    public static class BookingPassenger {
        public Long bookingId;
        public String email;
        public Integer passengerId;
        public String firstName;
        public String lastName;
        public BookingPassenger(Long bookingId, String email, Integer passengerId, String firstName, String lastName) {
            this.bookingId = bookingId;
            this.email = email;
            this.passengerId = passengerId;
            this.firstName = firstName;
            this.lastName = lastName;
        }
    }

    // HQ04: Account Relationship Graph with Optional Sub-Entities
    public static List<AccountGraph> hq04AccountGraph(DSLContext ctx, int minAcc, int maxAcc) {
        var records = ctx.select(
                ACCOUNT.ACCOUNT_ID, ACCOUNT.LOGIN,
                FREQUENT_FLYER.FREQUENT_FLYER_ID, FREQUENT_FLYER.AWARD_POINTS,
                BOOKING.BOOKING_ID, BOOKING.EMAIL,
                PASSENGER.PASSENGER_ID, PASSENGER.FIRST_NAME, PASSENGER.LAST_NAME
        )
        .from(ACCOUNT)
        .leftJoin(FREQUENT_FLYER).on(ACCOUNT.FREQUENT_FLYER_ID.eq(FREQUENT_FLYER.FREQUENT_FLYER_ID))
        .leftJoin(BOOKING).on(ACCOUNT.ACCOUNT_ID.eq(BOOKING.ACCOUNT_ID))
        .leftJoin(PASSENGER).on(BOOKING.BOOKING_ID.eq(PASSENGER.BOOKING_ID))
        .where(ACCOUNT.ACCOUNT_ID.between(minAcc, maxAcc))
        .orderBy(ACCOUNT.ACCOUNT_ID.asc())
        .fetch();

        Map<Integer, AccountGraph> map = new LinkedHashMap<>();
        for (Record r : records) {
            Integer accId = r.get(ACCOUNT.ACCOUNT_ID);
            AccountGraph ag = map.computeIfAbsent(accId, id -> new AccountGraph(
                accId, r.get(ACCOUNT.LOGIN), r.get(FREQUENT_FLYER.FREQUENT_FLYER_ID), r.get(FREQUENT_FLYER.AWARD_POINTS)
            ));
            Long bId = r.get(BOOKING.BOOKING_ID);
            if (bId != null) {
                ag.bookings.add(new BookingPassenger(
                    bId, r.get(BOOKING.EMAIL),
                    r.get(PASSENGER.PASSENGER_ID), r.get(PASSENGER.FIRST_NAME), r.get(PASSENGER.LAST_NAME)
                ));
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
    public static List<RouteLedger> hq05RouteLedger(DSLContext ctx, Instant startTs, Instant endTs) {
        Tables.AirportTable orig = AIRPORT.as("orig");
        Tables.AirportTable dest = AIRPORT.as("dest");

        Field<Long> totalFlights = countDistinct(FLIGHT.FLIGHT_ID).cast(Long.class).as("total_flights");
        Field<Long> totalLegs = count(BOOKING_LEG.BOOKING_LEG_ID).cast(Long.class).as("total_legs");
        Field<Double> totalRevenue = round(sum(BOOKING.PRICE), 2).cast(Double.class).as("total_revenue");
        Field<Double> avgDelayMin = round(avg(field("EXTRACT(EPOCH FROM ({0} - {1})) / 60", Double.class, FLIGHT.ACTUAL_DEPARTURE, FLIGHT.SCHEDULED_DEPARTURE)), 2).cast(Double.class).as("avg_delay_min");
        Field<Double> onTimePct = round(field("100.0 * count(CASE WHEN {0} <= {1} + INTERVAL '15 minutes' THEN 1 END) / count({2})", Double.class, FLIGHT.ACTUAL_DEPARTURE, FLIGHT.SCHEDULED_DEPARTURE, FLIGHT.FLIGHT_ID), 2).cast(Double.class).as("on_time_pct");

        return ctx.select(
                orig.AIRPORT_CODE.as("origin"),
                dest.AIRPORT_CODE.as("destination"),
                AIRCRAFT.MODEL.as("model"),
                totalFlights, totalLegs, totalRevenue, avgDelayMin, onTimePct
        )
        .from(FLIGHT)
        .join(orig).on(FLIGHT.DEPARTURE_AIRPORT.eq(orig.AIRPORT_CODE))
        .join(dest).on(FLIGHT.ARRIVAL_AIRPORT.eq(dest.AIRPORT_CODE))
        .join(AIRCRAFT).on(FLIGHT.AIRCRAFT_CODE.eq(AIRCRAFT.CODE))
        .join(BOOKING_LEG).on(FLIGHT.FLIGHT_ID.eq(BOOKING_LEG.FLIGHT_ID))
        .join(BOOKING).on(BOOKING_LEG.BOOKING_ID.eq(BOOKING.BOOKING_ID))
        .where(FLIGHT.SCHEDULED_DEPARTURE.ge(startTs).and(FLIGHT.SCHEDULED_DEPARTURE.lt(endTs)))
        .groupBy(orig.AIRPORT_CODE, dest.AIRPORT_CODE, AIRCRAFT.MODEL)
        .having(countDistinct(FLIGHT.FLIGHT_ID).ge(3))
        .orderBy(totalRevenue.desc())
        .limit(50)
        .fetchInto(RouteLedger.class);
    }

    public record HubCentrality(
            String airportCode, String airportName, String city,
            Long departures, Long arrivals, Long destinations, Long fleetDiversity,
            Double avgDepDelay, Double avgArrDelay, Double score
    ) {}

    // HQ06: Chained Multi-Stage CTEs (Hub Centrality & Degree)
    public static List<HubCentrality> hq06HubCentrality(DSLContext ctx, Instant startTs, Instant endTs) {
        CommonTableExpression<?> fv = name("flight_volumes").as(
            select(
                FLIGHT.DEPARTURE_AIRPORT.as("airport_code"),
                count().cast(Long.class).as("departures_count"),
                round(avg(field("EXTRACT(EPOCH FROM ({0} - {1})) / 60", Double.class, FLIGHT.ACTUAL_DEPARTURE, FLIGHT.SCHEDULED_DEPARTURE)), 2).cast(Double.class).as("avg_dep_delay")
            )
            .from(FLIGHT)
            .where(FLIGHT.SCHEDULED_DEPARTURE.ge(startTs).and(FLIGHT.SCHEDULED_DEPARTURE.lt(endTs)).and(FLIGHT.ACTUAL_DEPARTURE.isNotNull()))
            .groupBy(FLIGHT.DEPARTURE_AIRPORT)
        );

        CommonTableExpression<?> av = name("arrival_volumes").as(
            select(
                FLIGHT.ARRIVAL_AIRPORT.as("airport_code"),
                count().cast(Long.class).as("arrivals_count"),
                round(avg(field("EXTRACT(EPOCH FROM ({0} - {1})) / 60", Double.class, FLIGHT.ACTUAL_ARRIVAL, FLIGHT.SCHEDULED_ARRIVAL)), 2).cast(Double.class).as("avg_arr_delay")
            )
            .from(FLIGHT)
            .where(FLIGHT.SCHEDULED_ARRIVAL.ge(startTs).and(FLIGHT.SCHEDULED_ARRIVAL.lt(endTs)).and(FLIGHT.ACTUAL_ARRIVAL.isNotNull()))
            .groupBy(FLIGHT.ARRIVAL_AIRPORT)
        );

        CommonTableExpression<?> rc = name("route_connectivity").as(
            select(
                FLIGHT.DEPARTURE_AIRPORT.as("airport_code"),
                countDistinct(FLIGHT.ARRIVAL_AIRPORT).cast(Long.class).as("unique_destinations"),
                countDistinct(FLIGHT.AIRCRAFT_CODE).cast(Long.class).as("fleet_diversity")
            )
            .from(FLIGHT)
            .where(FLIGHT.SCHEDULED_DEPARTURE.ge(startTs).and(FLIGHT.SCHEDULED_DEPARTURE.lt(endTs)))
            .groupBy(FLIGHT.DEPARTURE_AIRPORT)
        );

        Tables.AirportTable a = AIRPORT.as("a");
        return ctx.with(fv).with(av).with(rc)
            .select(
                a.AIRPORT_CODE.as("airportCode"),
                a.AIRPORT_NAME.as("airportName"),
                a.CITY.as("city"),
                coalesce(fv.field("departures_count", Long.class), 0L).as("departures"),
                coalesce(av.field("arrivals_count", Long.class), 0L).as("arrivals"),
                coalesce(rc.field("unique_destinations", Long.class), 0L).as("destinations"),
                coalesce(rc.field("fleet_diversity", Long.class), 0L).as("fleetDiversity"),
                coalesce(fv.field("avg_dep_delay", Double.class), 0.0).as("avgDepDelay"),
                coalesce(av.field("avg_arr_delay", Double.class), 0.0).as("avgArrDelay"),
                round(
                    field("((coalesce({0}, 0) + coalesce({1}, 0)) * (1.0 + coalesce({2}, 0) / 100.0) / (1.0 + greatest(coalesce({3}, 0), 0) / 10.0))",
                          Double.class,
                          fv.field("departures_count"), av.field("arrivals_count"),
                          rc.field("unique_destinations"), fv.field("avg_dep_delay")),
                    2
                ).cast(Double.class).as("score")
            )
            .from(a)
            .join(fv).on(a.AIRPORT_CODE.eq(fv.field("airport_code", String.class)))
            .join(av).on(a.AIRPORT_CODE.eq(av.field("airport_code", String.class)))
            .join(rc).on(a.AIRPORT_CODE.eq(rc.field("airport_code", String.class)))
            .orderBy(field(name("score")).desc())
            .limit(50)
            .fetchInto(HubCentrality.class);
    }

    public record CapacityRiskFlight(
            Integer flightId, String flightNo, String depAirport, String arrAirport,
            Instant scheduledDep, String aircraftModel, Long seatsBooked, Long eliteFlyers
    ) {}

    // HQ07: Correlated At-Capacity Subquery with Loyalty Tier Cross-Check
    public static List<CapacityRiskFlight> hq07CapacityRiskFlights(DSLContext ctx, Instant startTs, Instant endTs) {
        Field<Long> seatsBooked = select(count().cast(Long.class))
            .from(BOOKING_LEG)
            .where(BOOKING_LEG.FLIGHT_ID.eq(FLIGHT.FLIGHT_ID))
            .asField("seatsBooked");

        Field<Long> eliteFlyers = select(count().cast(Long.class))
            .from(BOOKING_LEG)
            .join(PASSENGER).on(BOOKING_LEG.BOOKING_ID.eq(PASSENGER.BOOKING_ID))
            .join(ACCOUNT).on(PASSENGER.ACCOUNT_ID.eq(ACCOUNT.ACCOUNT_ID))
            .join(FREQUENT_FLYER).on(ACCOUNT.FREQUENT_FLYER_ID.eq(FREQUENT_FLYER.FREQUENT_FLYER_ID))
            .where(BOOKING_LEG.FLIGHT_ID.eq(FLIGHT.FLIGHT_ID).and(FREQUENT_FLYER.LEVEL.ge(3)))
            .asField("eliteFlyers");

        Condition seatsOver40 = select(count())
            .from(BOOKING_LEG)
            .where(BOOKING_LEG.FLIGHT_ID.eq(FLIGHT.FLIGHT_ID))
            .asField().gt(40);

        Condition existsAvailable = exists(
            selectOne().from(FLIGHT_SEAT_INVENTORY)
                .where(FLIGHT_SEAT_INVENTORY.FLIGHT_ID.eq(FLIGHT.FLIGHT_ID)
                       .and(FLIGHT_SEAT_INVENTORY.STATUS.eq("AVAILABLE")))
        );

        return ctx.select(
                FLIGHT.FLIGHT_ID.as("flightId"),
                FLIGHT.FLIGHT_NO.as("flightNo"),
                FLIGHT.DEPARTURE_AIRPORT.as("depAirport"),
                FLIGHT.ARRIVAL_AIRPORT.as("arrAirport"),
                FLIGHT.SCHEDULED_DEPARTURE.as("scheduledDep"),
                coalesce(AIRCRAFT.MODEL, "Unknown").as("aircraftModel"),
                seatsBooked, eliteFlyers
        )
        .from(FLIGHT)
        .join(AIRCRAFT).on(FLIGHT.AIRCRAFT_CODE.eq(AIRCRAFT.CODE))
        .where(FLIGHT.SCHEDULED_DEPARTURE.ge(startTs).and(FLIGHT.SCHEDULED_DEPARTURE.lt(endTs)))
        .and(AIRCRAFT.CLASS.ge(2))
        .and(seatsOver40)
        .and(existsAvailable)
        .orderBy(seatsBooked.desc())
        .limit(50)
        .fetchInto(CapacityRiskFlight.class);
    }

    public record ConnectingRoute(
            Integer hops, String path, Instant journeyStart, Instant journeyEnd,
            Double elapsedMinutes, Double flightMinutes
    ) {}

    // HQ08: Recursive Multi-Hop Flight Connection Graph Search
    public static List<ConnectingRoute> hq08RecursiveRouteSearch(DSLContext ctx, String origin, String dest, Instant startTs, Instant endTs) {
        Tables.FlightTable nextF = FLIGHT.as("next_f");

        Field<Integer> fpHops = field(name("flight_paths", "hops"), Integer.class);
        Field<String> fpDepAirport = field(name("flight_paths", "departure_airport"), String.class);
        Field<String> fpArrAirport = field(name("flight_paths", "arrival_airport"), String.class);
        Field<String[]> fpRouteAirports = field(name("flight_paths", "route_airports"), String[].class);
        Field<Integer[]> fpRouteFlights = field(name("flight_paths", "route_flights"), Integer[].class);
        Field<Instant> fpJourneyStart = field(name("flight_paths", "journey_start"), Instant.class);
        Field<Instant> fpJourneyEnd = field(name("flight_paths", "journey_end"), Instant.class);
        Field<Double> fpFlightMinutes = field(name("flight_paths", "total_flight_minutes"), Double.class);

        CommonTableExpression<?> fp = name("flight_paths").as(
            select(
                FLIGHT.FLIGHT_ID,
                FLIGHT.DEPARTURE_AIRPORT.cast(String.class).as("departure_airport"),
                FLIGHT.ARRIVAL_AIRPORT.cast(String.class).as("arrival_airport"),
                FLIGHT.SCHEDULED_DEPARTURE, FLIGHT.SCHEDULED_ARRIVAL,
                val(1).as("hops"),
                field("ARRAY[{0}::text, {1}::text]", String[].class, FLIGHT.DEPARTURE_AIRPORT, FLIGHT.ARRIVAL_AIRPORT).as("route_airports"),
                field("ARRAY[{0}]", Integer[].class, FLIGHT.FLIGHT_ID).as("route_flights"),
                FLIGHT.SCHEDULED_DEPARTURE.as("journey_start"),
                FLIGHT.SCHEDULED_ARRIVAL.as("journey_end"),
                field("(EXTRACT(EPOCH FROM ({0} - {1})) / 60)::float8", Double.class, FLIGHT.SCHEDULED_ARRIVAL, FLIGHT.SCHEDULED_DEPARTURE).as("total_flight_minutes")
            )
            .from(FLIGHT)
            .where(FLIGHT.DEPARTURE_AIRPORT.eq(origin)
                   .and(FLIGHT.SCHEDULED_DEPARTURE.ge(startTs))
                   .and(FLIGHT.SCHEDULED_DEPARTURE.lt(endTs)))
            .unionAll(
                select(
                    nextF.FLIGHT_ID,
                    fpDepAirport,
                    nextF.ARRIVAL_AIRPORT.cast(String.class),
                    nextF.SCHEDULED_DEPARTURE, nextF.SCHEDULED_ARRIVAL,
                    fpHops.plus(1),
                    field("{0} || {1}::text", String[].class, fpRouteAirports, nextF.ARRIVAL_AIRPORT),
                    field("{0} || {1}", Integer[].class, fpRouteFlights, nextF.FLIGHT_ID),
                    fpJourneyStart,
                    nextF.SCHEDULED_ARRIVAL,
                    fpFlightMinutes.plus(field("(EXTRACT(EPOCH FROM ({0} - {1})) / 60)::float8", Double.class, nextF.SCHEDULED_ARRIVAL, nextF.SCHEDULED_DEPARTURE))
                )
                .from(table(name("flight_paths")))
                .join(nextF).on(fpArrAirport.eq(nextF.DEPARTURE_AIRPORT.cast(String.class)))
                .where(fpHops.lt(3))
                .and(nextF.SCHEDULED_DEPARTURE.ge(field("{0} + INTERVAL '60 minutes'", Instant.class, fpJourneyEnd)))
                .and(nextF.SCHEDULED_DEPARTURE.le(field("{0} + INTERVAL '360 minutes'", Instant.class, fpJourneyEnd)))
                .and(field("NOT ({0}::text = ANY({1}))", Boolean.class, nextF.ARRIVAL_AIRPORT, fpRouteAirports))
            )
        );

        return ctx.withRecursive(fp)
            .select(
                fpHops.as("hops"),
                field("array_to_string({0}, ' -> ')", String.class, fpRouteAirports).as("path"),
                fpJourneyStart.as("journeyStart"),
                fpJourneyEnd.as("journeyEnd"),
                field("(EXTRACT(EPOCH FROM ({0} - {1})) / 60)::float8", Double.class, fpJourneyEnd, fpJourneyStart).as("elapsedMinutes"),
                fpFlightMinutes.as("flightMinutes")
            )
            .from(table(name("flight_paths")))
            .where(fpArrAirport.eq(dest))
            .orderBy(fpHops.asc(), field(name("elapsedMinutes")).asc())
            .limit(25)
            .fetchInto(ConnectingRoute.class);
    }

    public record DelayWindowAnalytics(
            Integer flightId, String flightNo, String arrAirport, Instant scheduledDep,
            Double delayMin, Double rollingAvg5, Double delayDiffPrev, Double rollingStdDev10, Long severityRank
    ) {}

    // HQ09: Multi-Window Statistical Delay Dispersion & Cascades
    public static List<DelayWindowAnalytics> hq09MultiWindowDelay(DSLContext ctx, String airport, Instant startTs, Instant endTs) {
        Field<Integer> fid = field(name("flight_delays", "flight_id"), Integer.class);
        Field<String> fno = field(name("flight_delays", "flight_no"), String.class);
        Field<String> depA = field(name("flight_delays", "departure_airport"), String.class);
        Field<String> arrA = field(name("flight_delays", "arrival_airport"), String.class);
        Field<Instant> schedD = field(name("flight_delays", "scheduled_departure"), Instant.class);
        Field<Double> delayMin = field(name("flight_delays", "delay_minutes"), Double.class);

        CommonTableExpression<?> fd = name("flight_delays").as(
            select(
                FLIGHT.FLIGHT_ID, FLIGHT.FLIGHT_NO, FLIGHT.DEPARTURE_AIRPORT, FLIGHT.ARRIVAL_AIRPORT,
                FLIGHT.SCHEDULED_DEPARTURE, FLIGHT.ACTUAL_DEPARTURE,
                round(field("(EXTRACT(EPOCH FROM ({0} - {1})) / 60)::numeric", Double.class, FLIGHT.ACTUAL_DEPARTURE, FLIGHT.SCHEDULED_DEPARTURE), 2).cast(Double.class).as("delay_minutes")
            )
            .from(FLIGHT)
            .where(FLIGHT.DEPARTURE_AIRPORT.eq(airport)
                   .and(FLIGHT.ACTUAL_DEPARTURE.isNotNull())
                   .and(FLIGHT.SCHEDULED_DEPARTURE.ge(startTs))
                   .and(FLIGHT.SCHEDULED_DEPARTURE.lt(endTs)))
        );

        return ctx.with(fd)
            .select(
                fid.as("flightId"),
                fno.as("flightNo"),
                arrA.as("arrAirport"),
                schedD.as("scheduledDep"),
                delayMin.as("delayMin"),
                round(avg(delayMin).over(partitionBy(depA, arrA).orderBy(schedD).rowsBetweenPreceding(4).andCurrentRow()).cast(BigDecimal.class), 2).cast(Double.class).as("rollingAvg5"),
                (delayMin.minus(lag(delayMin, 1).over(partitionBy(depA, arrA).orderBy(schedD)))).cast(Double.class).as("delayDiffPrev"),
                round(coalesce(field("stddev_samp({0}) OVER (PARTITION BY {1}, {2} ORDER BY {3} ROWS BETWEEN 9 PRECEDING AND CURRENT ROW)", Double.class, delayMin, depA, arrA, schedD), 0.0).cast(BigDecimal.class), 2).cast(Double.class).as("rollingStdDev10"),
                denseRank().over(partitionBy(depA, arrA).orderBy(delayMin.desc())).cast(Long.class).as("severityRank")
            )
            .from(table(name("flight_delays")))
            .orderBy(depA.asc(), arrA.asc(), schedD.asc())
            .limit(5000)
            .fetchInto(DelayWindowAnalytics.class);
    }

    // HQ10: Keyset (Cursor) Pagination over Composite Tuple Under Load
    public static List<Flight> hq10KeysetPagination(DSLContext ctx, Instant cursorTs, int cursorId, int limit) {
        return ctx.selectFrom(FLIGHT)
            .where(
                FLIGHT.SCHEDULED_DEPARTURE.ge(cursorTs)
                .and(FLIGHT.SCHEDULED_DEPARTURE.gt(cursorTs).or(FLIGHT.FLIGHT_ID.gt(cursorId)))
            )
            .orderBy(FLIGHT.SCHEDULED_DEPARTURE.asc(), FLIGHT.FLIGHT_ID.asc())
            .limit(limit)
            .fetchInto(Flight.class);
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
    public static List<Flight> hq11DynamicFacetedSearch(DSLContext ctx, FlightSearchParams params) {
        var query = ctx.select(FLIGHT.asterisk())
            .from(FLIGHT)
            .join(AIRCRAFT).on(FLIGHT.AIRCRAFT_CODE.eq(AIRCRAFT.CODE));

        List<Condition> conditions = new ArrayList<>();
        if (params.origins != null && !params.origins.isEmpty()) {
            conditions.add(FLIGHT.DEPARTURE_AIRPORT.in(params.origins));
        }
        if (params.destinations != null && !params.destinations.isEmpty()) {
            conditions.add(FLIGHT.ARRIVAL_AIRPORT.in(params.destinations));
        }
        if (params.minDeparture != null) {
            conditions.add(FLIGHT.SCHEDULED_DEPARTURE.ge(params.minDeparture));
        }
        if (params.maxDeparture != null) {
            conditions.add(FLIGHT.SCHEDULED_DEPARTURE.le(params.maxDeparture));
        }
        if (params.aircraftClass != null && !params.aircraftClass.isEmpty()) {
            conditions.add(AIRCRAFT.CLASS.in(params.aircraftClass));
        }
        if (params.minRange != null) {
            conditions.add(AIRCRAFT.RANGE.ge(params.minRange));
        }
        if (params.statuses != null && !params.statuses.isEmpty()) {
            conditions.add(FLIGHT.STATUS.in(params.statuses));
        }
        if (params.cursorTime != null && params.cursorId != null) {
            conditions.add(
                FLIGHT.SCHEDULED_DEPARTURE.gt(params.cursorTime)
                .or(FLIGHT.SCHEDULED_DEPARTURE.eq(params.cursorTime).and(FLIGHT.FLIGHT_ID.gt(params.cursorId)))
            );
        }

        return query.where(conditions)
            .orderBy(FLIGHT.SCHEDULED_DEPARTURE.asc(), FLIGHT.FLIGHT_ID.asc())
            .limit(params.limit)
            .fetchInto(Flight.class);
    }

    // HQ12: High-Volume Batch Upsert (2,500 Records ON CONFLICT)
    public static int hq12BatchUpsert(DSLContext ctx, List<FlightStatusUpdate> batch) {
        var insert = ctx.insertInto(FLIGHT_STATUS_UPDATE,
                FLIGHT_STATUS_UPDATE.FLIGHT_ID,
                FLIGHT_STATUS_UPDATE.STATUS,
                FLIGHT_STATUS_UPDATE.ACTUAL_DEPARTURE,
                FLIGHT_STATUS_UPDATE.ACTUAL_ARRIVAL,
                FLIGHT_STATUS_UPDATE.UPDATE_TS,
                FLIGHT_STATUS_UPDATE.VERSION
        );

        for (FlightStatusUpdate u : batch) {
            insert = insert.values(
                u.getFlightId(), u.getStatus(), u.getActualDeparture(), u.getActualArrival(), u.getUpdateTs(), u.getVersion()
            );
        }

        return insert.onConflict(FLIGHT_STATUS_UPDATE.FLIGHT_ID)
            .doUpdate()
            .set(FLIGHT_STATUS_UPDATE.STATUS, DSL.excluded(FLIGHT_STATUS_UPDATE.STATUS))
            .set(FLIGHT_STATUS_UPDATE.ACTUAL_DEPARTURE, DSL.excluded(FLIGHT_STATUS_UPDATE.ACTUAL_DEPARTURE))
            .set(FLIGHT_STATUS_UPDATE.ACTUAL_ARRIVAL, DSL.excluded(FLIGHT_STATUS_UPDATE.ACTUAL_ARRIVAL))
            .set(FLIGHT_STATUS_UPDATE.UPDATE_TS, DSL.excluded(FLIGHT_STATUS_UPDATE.UPDATE_TS))
            .set(FLIGHT_STATUS_UPDATE.VERSION, FLIGHT_STATUS_UPDATE.VERSION.plus(1))
            .execute();
    }

    // HQ13: Optimistic Concurrency Bulk Fare & Status Adjustment
    public static int hq13OptimisticBulkUpdate(DSLContext ctx, int minFid, int maxFid, int expectedVer, String newStatus) {
        return ctx.update(FLIGHT)
            .set(FLIGHT.STATUS, newStatus)
            .set(FLIGHT.VERSION, FLIGHT.VERSION.plus(1))
            .set(FLIGHT.UPDATE_TS, DSL.currentInstant())
            .where(FLIGHT.FLIGHT_ID.between(minFid, maxFid).and(FLIGHT.VERSION.eq(expectedVer)))
            .execute();
    }

    // =========================================================================
    // Category VI: Concurrency Contention, Transactions & Multi-Modal Search
    // =========================================================================

    // HQ14: High-Concurrency Seat Allocation Under Contention (C=100)
    public static String hq14ReserveSeatConcurrent(DSLContext ctx, int flightId, String passengerName) {
        return ctx.transactionResult(configuration -> {
            DSLContext tx = DSL.using(configuration);
            Record2<String, Integer> row = tx.select(FLIGHT_SEAT_INVENTORY.SEAT_NO, FLIGHT_SEAT_INVENTORY.VERSION)
                .from(FLIGHT_SEAT_INVENTORY)
                .where(FLIGHT_SEAT_INVENTORY.FLIGHT_ID.eq(flightId)
                       .and(FLIGHT_SEAT_INVENTORY.STATUS.eq("AVAILABLE")))
                .limit(1)
                .forUpdate()
                .fetchOne();

            if (row == null) {
                return "Sold Out";
            }

            String seatNo = row.value1();
            int ver = row.value2();

            int updated = tx.update(FLIGHT_SEAT_INVENTORY)
                .set(FLIGHT_SEAT_INVENTORY.STATUS, "RESERVED")
                .set(FLIGHT_SEAT_INVENTORY.PASSENGER_NAME, passengerName)
                .set(FLIGHT_SEAT_INVENTORY.RESERVED_AT, DSL.currentInstant())
                .set(FLIGHT_SEAT_INVENTORY.VERSION, FLIGHT_SEAT_INVENTORY.VERSION.plus(1))
                .where(FLIGHT_SEAT_INVENTORY.FLIGHT_ID.eq(flightId)
                       .and(FLIGHT_SEAT_INVENTORY.SEAT_NO.eq(seatNo))
                       .and(FLIGHT_SEAT_INVENTORY.VERSION.eq(ver)))
                .execute();

            return updated > 0 ? seatNo : "Sold Out";
        });
    }

    // HQ15: Distributed Financial / Points Transfer with Serialization Retry
    public static void hq15PointsTransferSerializable(DSLContext ctx, int fromAcc, int toAcc, int points) throws Exception {
        int maxRetries = 5;
        for (int attempt = 0; attempt < maxRetries; attempt++) {
            try {
                ctx.transaction(configuration -> {
                    DSLContext tx = DSL.using(configuration);
                    tx.execute("SET TRANSACTION ISOLATION LEVEL SERIALIZABLE");

                    tx.update(FREQUENT_FLYER)
                        .set(FREQUENT_FLYER.AWARD_POINTS, FREQUENT_FLYER.AWARD_POINTS.minus(points))
                        .where(FREQUENT_FLYER.FREQUENT_FLYER_ID.eq(fromAcc))
                        .execute();

                    tx.update(FREQUENT_FLYER)
                        .set(FREQUENT_FLYER.AWARD_POINTS, FREQUENT_FLYER.AWARD_POINTS.plus(points))
                        .where(FREQUENT_FLYER.FREQUENT_FLYER_ID.eq(toAcc))
                        .execute();
                });
                return;
            } catch (Exception e) {
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
    public static List<HybridSearchResult> hq16HybridSearchRRF(DSLContext ctx, String targetAirport, String queryText) {
        Field<String> trAirportCode = field(name("text_ranking", "airport_code"), String.class);
        Field<Long> trRankText = field(name("text_ranking", "rank_text"), Long.class);

        Field<String> vrAirportCode = field(name("vector_ranking", "airport_code"), String.class);
        Field<Long> vrRankVec = field(name("vector_ranking", "rank_vec"), Long.class);

        Field<String> astAirportCode = field(name("airport_stats", "airport_code"), String.class);
        Field<Long> astCount = field(name("airport_stats", "active_flights_count"), Long.class);

        Field<String> rrfAirportCode = field(name("rrf_scores", "airport_code"), String.class);
        Field<Double> rrfScore = field(name("rrf_scores", "rrf_score"), Double.class);

        CommonTableExpression<?> tr = name("text_ranking").as(
            select(
                AIRPORT.AIRPORT_CODE.as("airport_code"),
                rowNumber().over(orderBy(field("ts_rank_cd(search_tsv, plainto_tsquery('english', {0}))", Double.class, queryText).desc())).as("rank_text")
            )
            .from(AIRPORT)
            .where(field("search_tsv @@ plainto_tsquery('english', {0})", Boolean.class, queryText))
            .limit(25)
        );

        CommonTableExpression<?> vr = name("vector_ranking").as(
            select(
                AIRPORT.AIRPORT_CODE.as("airport_code"),
                rowNumber().over(orderBy(field("(embedding <=> (SELECT embedding FROM postgres_air.airport WHERE airport_code = {0}))", Double.class, targetAirport).asc())).as("rank_vec")
            )
            .from(AIRPORT)
            .limit(25)
        );

        CommonTableExpression<?> ast = name("airport_stats").as(
            select(
                FLIGHT.DEPARTURE_AIRPORT.as("airport_code"),
                count().cast(Long.class).as("active_flights_count")
            )
            .from(FLIGHT)
            .where(FLIGHT.SCHEDULED_DEPARTURE.ge(Instant.parse("2024-07-01T00:00:00Z"))
                   .and(FLIGHT.SCHEDULED_DEPARTURE.lt(Instant.parse("2024-07-15T00:00:00Z"))))
            .groupBy(FLIGHT.DEPARTURE_AIRPORT)
        );

        CommonTableExpression<?> rrf = name("rrf_scores").as(
            select(
                coalesce(trAirportCode, vrAirportCode).as("airport_code"),
                field("(coalesce(1.0 / (60.0 + {0}), 0.0) + coalesce(1.0 / (60.0 + {1}), 0.0))::float8", Double.class, trRankText, vrRankVec).as("rrf_score")
            )
            .from(table(name("text_ranking")))
            .fullOuterJoin(table(name("vector_ranking"))).on(trAirportCode.eq(vrAirportCode))
        );

        Tables.AirportTable a = AIRPORT.as("a");
        return ctx.with(tr).with(vr).with(ast).with(rrf)
            .select(
                a.AIRPORT_CODE.as("airportCode"),
                a.AIRPORT_NAME.as("airportName"),
                a.CITY.as("city"),
                coalesce(astCount, 0L).as("activeFlights"),
                round(rrfScore.cast(BigDecimal.class), 6).cast(Double.class).as("rrfScore")
            )
            .from(table(name("rrf_scores")))
            .join(a).on(rrfAirportCode.eq(a.AIRPORT_CODE))
            .leftJoin(table(name("airport_stats"))).on(a.AIRPORT_CODE.eq(astAirportCode))
            .orderBy(field(name("rrfScore")).desc())
            .limit(10)
            .fetchInto(HybridSearchResult.class);
    }
}
