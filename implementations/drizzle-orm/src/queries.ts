import {
  eq,
  between,
  asc,
  desc,
  and,
  or,
  gt,
  gte,
  lt,
  lte,
  inArray,
  sql,
  type SQL,
} from 'drizzle-orm';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import {
  flight,
  booking,
  passenger,
  bookingLeg,
  boardingPass,
  account,
  frequentFlyer,
  phone,
  airport,
  aircraft,
  flightSeatInventory,
  flightStatusUpdate,
} from './schema.js';

// HQ01: Massive Entity Deserialization (10,000 Wide Rows)
export async function hq01MassiveDeserialization(db: NodePgDatabase<any>) {
  return await db
    .select()
    .from(flight)
    .orderBy(asc(flight.flightId))
    .limit(10000);
}

// HQ02: Wide Multi-Join Composite Hydration (5,000 Joined Records Across 4 Relations)
export async function hq02WideMultiJoin(db: NodePgDatabase<any>) {
  return await db
    .select({
      bookingId: booking.bookingId,
      bookingRef: booking.bookingRef,
      price: booking.price,
      email: booking.email,
      passengerId: passenger.passengerId,
      firstName: passenger.firstName,
      lastName: passenger.lastName,
      age: passenger.age,
      bookingLegId: bookingLeg.bookingLegId,
      legNum: bookingLeg.legNum,
      isReturning: bookingLeg.isReturning,
      flightId: flight.flightId,
      flightNo: flight.flightNo,
      departureAirport: flight.departureAirport,
      arrivalAirport: flight.arrivalAirport,
      scheduledDeparture: flight.scheduledDeparture,
      status: flight.status,
    })
    .from(booking)
    .innerJoin(passenger, eq(booking.bookingId, passenger.bookingId))
    .innerJoin(bookingLeg, eq(booking.bookingId, bookingLeg.bookingId))
    .innerJoin(flight, eq(bookingLeg.flightId, flight.flightId))
    .where(between(booking.bookingId, 100000, 105000))
    .orderBy(asc(booking.bookingId), asc(passenger.passengerId), asc(bookingLeg.bookingLegId))
    .limit(5000);
}

// HQ03: 4-Level Deep Hierarchical Entity Tree Materialization
export async function hq03DeepHierarchicalGraph(db: NodePgDatabase<any>) {
  const rows = await db
    .select({
      flightId: flight.flightId,
      flightNo: flight.flightNo,
      departureAirport: flight.departureAirport,
      arrivalAirport: flight.arrivalAirport,
      scheduledDeparture: flight.scheduledDeparture,
      bookingLegId: bookingLeg.bookingLegId,
      legNum: bookingLeg.legNum,
      bookingId: booking.bookingId,
      bookingRef: booking.bookingRef,
      price: booking.price,
      passId: boardingPass.passId,
      seat: boardingPass.seat,
      boardingTime: boardingPass.boardingTime,
    })
    .from(flight)
    .innerJoin(bookingLeg, eq(flight.flightId, bookingLeg.flightId))
    .innerJoin(booking, eq(bookingLeg.bookingId, booking.bookingId))
    .leftJoin(boardingPass, eq(boardingPass.bookingLegId, sql`${bookingLeg.bookingLegId}::bigint`))
    .where(between(flight.flightId, 2000, 2025))
    .orderBy(asc(flight.flightId), asc(bookingLeg.bookingLegId), asc(boardingPass.passId));

  const map = new Map<number, any>();
  for (const r of rows) {
    let f = map.get(r.flightId);
    if (!f) {
      f = {
        flightId: r.flightId,
        flightNo: r.flightNo,
        departureAirport: r.departureAirport,
        arrivalAirport: r.arrivalAirport,
        scheduledDeparture: r.scheduledDeparture,
        legs: [] as any[],
      };
      map.set(r.flightId, f);
    }
    let leg = f.legs.find((l: any) => l.bookingLegId === r.bookingLegId);
    if (!leg) {
      leg = {
        bookingLegId: r.bookingLegId,
        legNum: r.legNum,
        bookingId: r.bookingId,
        bookingRef: r.bookingRef,
        price: r.price,
        boardingPass: r.passId ? { passId: r.passId, seat: r.seat, boardingTime: r.boardingTime } : null,
      };
      f.legs.push(leg);
    }
  }
  return Array.from(map.values());
}

// HQ04: Account Relationship Graph with Optional Sub-Entities
export async function hq04AccountRelationshipGraph(db: NodePgDatabase<any>) {
  const rows = await db
    .select({
      accountId: account.accountId,
      login: account.login,
      firstName: account.firstName,
      lastName: account.lastName,
      ffId: frequentFlyer.frequentFlyerId,
      ffLevel: frequentFlyer.level,
      ffPoints: frequentFlyer.awardPoints,
      phoneId: phone.phoneId,
      phoneNumber: phone.phoneNumber,
      phoneType: phone.phoneType,
      bookingId: booking.bookingId,
      bookingRef: booking.bookingRef,
      bookingPrice: booking.price,
      passengerId: passenger.passengerId,
      passengerFirstName: passenger.firstName,
      passengerLastName: passenger.lastName,
    })
    .from(account)
    .leftJoin(frequentFlyer, eq(account.frequentFlyerId, frequentFlyer.frequentFlyerId))
    .leftJoin(phone, eq(account.accountId, phone.accountId))
    .leftJoin(booking, eq(account.accountId, booking.accountId))
    .leftJoin(passenger, eq(booking.bookingId, passenger.bookingId))
    .where(between(account.accountId, 50000, 50200))
    .orderBy(asc(account.accountId), asc(phone.phoneId), asc(booking.bookingId), asc(passenger.passengerId));

  const map = new Map<number, any>();
  for (const r of rows) {
    let acc = map.get(r.accountId);
    if (!acc) {
      acc = {
        accountId: r.accountId,
        login: r.login,
        firstName: r.firstName,
        lastName: r.lastName,
        frequentFlyer: r.ffId ? { id: r.ffId, level: r.ffLevel, points: r.ffPoints } : null,
        phones: [] as any[],
        bookings: [] as any[],
      };
      map.set(r.accountId, acc);
    }
    if (r.phoneId && !acc.phones.some((p: any) => p.phoneId === r.phoneId)) {
      acc.phones.push({ phoneId: r.phoneId, phone: r.phoneNumber, type: r.phoneType });
    }
    if (r.bookingId) {
      let b = acc.bookings.find((bk: any) => bk.bookingId === r.bookingId);
      if (!b) {
        b = {
          bookingId: r.bookingId,
          bookingRef: r.bookingRef,
          price: r.bookingPrice,
          passengers: [] as any[],
        };
        acc.bookings.push(b);
      }
      if (r.passengerId && !b.passengers.some((p: any) => p.passengerId === r.passengerId)) {
        b.passengers.push({
          passengerId: r.passengerId,
          firstName: r.passengerFirstName,
          lastName: r.passengerLastName,
        });
      }
    }
  }
  return Array.from(map.values());
}

// HQ05: Fleet & Route Profitability Analytical Ledger
export async function hq05RouteFinancialLedger(db: NodePgDatabase<any>) {
  return await db
    .select({
      origin: flight.departureAirport,
      destination: flight.arrivalAirport,
      aircraftModel: aircraft.model,
      totalFlights: sql<number>`count(distinct ${flight.flightId})::bigint`,
      totalLegsBooked: sql<number>`count(${bookingLeg.bookingLegId})::bigint`,
      totalRevenue: sql<string>`round(sum(${booking.price}), 2)`,
      avgDelayMinutes: sql<string>`round(avg(extract(epoch from (${flight.actualDeparture} - ${flight.scheduledDeparture})) / 60)::numeric, 2)`,
      onTimePct: sql<string>`round(100.0 * count(case when ${flight.actualDeparture} <= ${flight.scheduledDeparture} + interval '15 minutes' then 1 end) / count(${flight.flightId}), 2)`,
    })
    .from(flight)
    .innerJoin(aircraft, eq(flight.aircraftCode, aircraft.code))
    .innerJoin(bookingLeg, eq(flight.flightId, bookingLeg.flightId))
    .innerJoin(booking, eq(bookingLeg.bookingId, booking.bookingId))
    .where(
      and(
        gte(flight.scheduledDeparture, new Date('2024-07-01T00:00:00Z')),
        lt(flight.scheduledDeparture, new Date('2024-07-04T00:00:00Z'))
      )
    )
    .groupBy(flight.departureAirport, flight.arrivalAirport, aircraft.model)
    .having(gte(sql`count(distinct ${flight.flightId})`, 3))
    .orderBy(desc(sql`sum(${booking.price})`))
    .limit(50);
}

// HQ06: Chained Multi-Stage CTEs (Hub Centrality & Degree)
export async function hq06ChainedCtesHubCentrality(db: NodePgDatabase<any>) {
  const query = sql`
    WITH flight_volumes AS (
        SELECT departure_airport AS airport_code,
               count(*) AS departures_count,
               round(avg(EXTRACT(EPOCH FROM (actual_departure - scheduled_departure)) / 60)::numeric, 2) AS avg_dep_delay
        FROM postgres_air.flight
        WHERE scheduled_departure >= '2024-06-01 00:00:00+00' AND scheduled_departure < '2024-07-01 00:00:00+00'
          AND actual_departure IS NOT NULL
        GROUP BY departure_airport
    ),
    arrival_volumes AS (
        SELECT arrival_airport AS airport_code,
               count(*) AS arrivals_count,
               round(avg(EXTRACT(EPOCH FROM (actual_arrival - scheduled_arrival)) / 60)::numeric, 2) AS avg_arr_delay
        FROM postgres_air.flight
        WHERE scheduled_arrival >= '2024-06-01 00:00:00+00' AND scheduled_arrival < '2024-07-01 00:00:00+00'
          AND actual_arrival IS NOT NULL
        GROUP BY arrival_airport
    ),
    route_connectivity AS (
        SELECT departure_airport AS airport_code,
               count(DISTINCT arrival_airport) AS unique_destinations,
               count(DISTINCT aircraft_code) AS fleet_diversity
        FROM postgres_air.flight
        WHERE scheduled_departure >= '2024-06-01 00:00:00+00' AND scheduled_departure < '2024-07-01 00:00:00+00'
        GROUP BY departure_airport
    )
    SELECT a.airport_code,
           a.airport_name,
           a.city,
           coalesce(fv.departures_count, 0) AS total_departures,
           coalesce(av.arrivals_count, 0) AS total_arrivals,
           coalesce(rc.unique_destinations, 0) AS unique_destinations,
           coalesce(rc.fleet_diversity, 0) AS fleet_diversity,
           coalesce(fv.avg_dep_delay, 0) AS avg_dep_delay,
           coalesce(av.avg_arr_delay, 0) AS avg_arr_delay,
           round(
               (coalesce(fv.departures_count, 0) + coalesce(av.arrivals_count, 0)) * 
               (1.0 + coalesce(rc.unique_destinations, 0) / 100.0) / 
               (1.0 + greatest(coalesce(fv.avg_dep_delay, 0), 0) / 10.0), 
               2
           ) AS hub_centrality_score
    FROM postgres_air.airport a
    JOIN flight_volumes fv ON a.airport_code = fv.airport_code
    JOIN arrival_volumes av ON a.airport_code = av.airport_code
    JOIN route_connectivity rc ON a.airport_code = rc.airport_code
    ORDER BY hub_centrality_score DESC
    LIMIT 50;
  `;
  const res = await db.execute(query);
  return res.rows;
}

// HQ07: Correlated At-Capacity Subquery + Loyalty Cross-Check
export async function hq07CorrelatedSubqueries(db: NodePgDatabase<any>) {
  return await db
    .select({
      flightId: flight.flightId,
      flightNo: flight.flightNo,
      departureAirport: flight.departureAirport,
      arrivalAirport: flight.arrivalAirport,
      scheduledDeparture: flight.scheduledDeparture,
      aircraftModel: aircraft.model,
      aircraftRange: aircraft.range,
      seatsBooked: sql<number>`(SELECT count(*) FROM postgres_air.booking_leg bl WHERE bl.flight_id = ${flight.flightId})::bigint`,
      eliteFlyerCount: sql<number>`(SELECT count(*) FROM postgres_air.booking_leg bl JOIN postgres_air.passenger p ON bl.booking_id = p.booking_id JOIN postgres_air.account a ON p.account_id = a.account_id JOIN postgres_air.frequent_flyer ff ON a.frequent_flyer_id = ff.frequent_flyer_id WHERE bl.flight_id = ${flight.flightId} AND ff.level >= 3)::bigint`,
    })
    .from(flight)
    .innerJoin(aircraft, eq(flight.aircraftCode, aircraft.code))
    .where(
      and(
        gte(flight.scheduledDeparture, new Date('2024-07-01T00:00:00Z')),
        lt(flight.scheduledDeparture, new Date('2024-07-03T00:00:00Z')),
        gte(aircraft.class, 2),
        sql`(SELECT count(*) FROM postgres_air.booking_leg bl WHERE bl.flight_id = ${flight.flightId}) > 40`,
        sql`EXISTS (SELECT 1 FROM postgres_air.flight route_f WHERE route_f.departure_airport = ${flight.departureAirport} AND route_f.arrival_airport = ${flight.arrivalAirport} AND route_f.status = 'Canceled' AND route_f.scheduled_departure >= '2024-06-01 00:00:00+00')`
      )
    )
    .orderBy(desc(sql`(SELECT count(*) FROM postgres_air.booking_leg bl WHERE bl.flight_id = ${flight.flightId})`))
    .limit(100);
}

// HQ08: Recursive Multi-Hop Flight Connection Graph Search (1-3 Hops)
export async function hq08RecursiveMultiHop(db: NodePgDatabase<any>) {
  const query = sql`
    WITH RECURSIVE flight_paths AS (
        SELECT f.flight_id,
               f.departure_airport::text AS departure_airport,
               f.arrival_airport::text AS arrival_airport,
               f.scheduled_departure,
               f.scheduled_arrival,
               1 AS hops,
               ARRAY[f.departure_airport::text, f.arrival_airport::text] AS route_airports,
               ARRAY[f.flight_id] AS route_flights,
               f.scheduled_departure AS journey_start,
               f.scheduled_arrival AS journey_end,
               (EXTRACT(EPOCH FROM (f.scheduled_arrival - f.scheduled_departure)) / 60)::numeric(10,2) AS total_flight_minutes
        FROM postgres_air.flight f
        WHERE f.departure_airport = 'JFK'
          AND f.scheduled_departure >= '2024-07-05 00:00:00+00'
          AND f.scheduled_departure < '2024-07-06 00:00:00+00'

        UNION ALL

        SELECT next_f.flight_id,
               fp.departure_airport,
               next_f.arrival_airport::text,
               next_f.scheduled_departure,
               next_f.scheduled_arrival,
               fp.hops + 1,
               fp.route_airports || next_f.arrival_airport::text,
               fp.route_flights || next_f.flight_id,
               fp.journey_start,
               next_f.scheduled_arrival,
               (fp.total_flight_minutes + (EXTRACT(EPOCH FROM (next_f.scheduled_arrival - next_f.scheduled_departure)) / 60))::numeric(10,2)
        FROM flight_paths fp
        JOIN postgres_air.flight next_f ON fp.arrival_airport = next_f.departure_airport
        WHERE fp.hops < 3
          AND next_f.scheduled_departure >= fp.scheduled_arrival + INTERVAL '60 minutes'
          AND next_f.scheduled_departure <= fp.scheduled_arrival + INTERVAL '360 minutes'
          AND NOT (next_f.arrival_airport::text = ANY(fp.route_airports))
    )
    SELECT hops,
           array_to_string(route_airports, ' -> ') AS route,
           journey_start,
           journey_end,
           (EXTRACT(EPOCH FROM (journey_end - journey_start)) / 60)::numeric(10,2) AS total_elapsed_minutes,
           total_flight_minutes
    FROM flight_paths
    WHERE arrival_airport = 'ORD'
    ORDER BY hops ASC, total_elapsed_minutes ASC
    LIMIT 25;
  `;
  const res = await db.execute(query);
  return res.rows;
}

// HQ09: Multi-Window Statistical Delay Dispersion & Cascades
export async function hq09WindowStatisticalDispersion(db: NodePgDatabase<any>) {
  const query = sql`
    WITH flight_delays AS (
        SELECT flight_id,
               flight_no,
               departure_airport,
               arrival_airport,
               scheduled_departure,
               actual_departure,
               round((EXTRACT(EPOCH FROM (actual_departure - scheduled_departure)) / 60)::numeric, 2) AS delay_minutes
        FROM postgres_air.flight
        WHERE departure_airport = 'ORD'
          AND actual_departure IS NOT NULL
          AND scheduled_departure >= '2024-06-01 00:00:00+00'
          AND scheduled_departure < '2024-07-01 00:00:00+00'
    )
    SELECT flight_id,
           flight_no,
           arrival_airport,
           scheduled_departure,
           delay_minutes,
           round(avg(delay_minutes) OVER (
               PARTITION BY departure_airport, arrival_airport 
               ORDER BY scheduled_departure 
               ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
           ), 2) AS rolling_avg_delay_5,
           delay_minutes - lag(delay_minutes, 1) OVER (
               PARTITION BY departure_airport, arrival_airport 
               ORDER BY scheduled_departure
           ) AS delay_diff_prev,
           round(coalesce(stddev_samp(delay_minutes) OVER (
               PARTITION BY departure_airport, arrival_airport 
               ORDER BY scheduled_departure 
               ROWS BETWEEN 9 PRECEDING AND CURRENT ROW
           ), 0), 2) AS rolling_stddev_10,
           dense_rank() OVER (
               PARTITION BY departure_airport, arrival_airport 
               ORDER BY delay_minutes DESC
           ) AS severity_rank
    FROM flight_delays
    ORDER BY departure_airport, arrival_airport, scheduled_departure
    LIMIT 5000;
  `;
  const res = await db.execute(query);
  return res.rows;
}

// HQ10: Keyset (Cursor) Pagination over Composite Tuple Under Concurrency
export async function hq10KeysetPagination(
  db: NodePgDatabase<any>,
  cursorTime: Date,
  cursorId: number
) {
  return await db
    .select({
      flightId: flight.flightId,
      flightNo: flight.flightNo,
      departureAirport: flight.departureAirport,
      arrivalAirport: flight.arrivalAirport,
      scheduledDeparture: flight.scheduledDeparture,
      status: flight.status,
    })
    .from(flight)
    .where(
      or(
        gt(flight.scheduledDeparture, cursorTime),
        and(eq(flight.scheduledDeparture, cursorTime), gt(flight.flightId, cursorId))
      )
    )
    .orderBy(asc(flight.scheduledDeparture), asc(flight.flightId))
    .limit(50);
}

// HQ11: High-Dimensional Dynamic Faceted Flight Search Engine (10 Optional Predicates)
export async function hq11DynamicFacetedSearch(
  db: NodePgDatabase<any>,
  depAirports?: string[],
  arrAirports?: string[],
  minDep?: Date,
  maxDep?: Date,
  aircraftClasses?: number[],
  minRange?: number,
  statuses?: string[],
  startHour?: number,
  endHour?: number,
  cursor?: { time: Date; id: number }
) {
  let query = db
    .select({
      flightId: flight.flightId,
      flightNo: flight.flightNo,
      departureAirport: flight.departureAirport,
      arrivalAirport: flight.arrivalAirport,
      scheduledDeparture: flight.scheduledDeparture,
      scheduledArrival: flight.scheduledArrival,
      status: flight.status,
      aircraftModel: aircraft.model,
      aircraftRange: aircraft.range,
      aircraftClass: aircraft.class,
    })
    .from(flight)
    .innerJoin(aircraft, eq(flight.aircraftCode, aircraft.code))
    .$dynamic();

  const conditions: SQL[] = [];
  if (depAirports && depAirports.length > 0) conditions.push(inArray(flight.departureAirport, depAirports));
  if (arrAirports && arrAirports.length > 0) conditions.push(inArray(flight.arrivalAirport, arrAirports));
  if (minDep) conditions.push(gte(flight.scheduledDeparture, minDep));
  if (maxDep) conditions.push(lte(flight.scheduledDeparture, maxDep));
  if (aircraftClasses && aircraftClasses.length > 0) conditions.push(inArray(aircraft.class, aircraftClasses));
  if (minRange != null) conditions.push(gte(aircraft.range, minRange.toString()));
  if (statuses && statuses.length > 0) conditions.push(inArray(flight.status, statuses));
  if (startHour != null && endHour != null) {
    conditions.push(sql`EXTRACT(HOUR FROM ${flight.scheduledDeparture}) BETWEEN ${startHour} AND ${endHour}`);
  }
  if (cursor) {
    conditions.push(
      or(
        gt(flight.scheduledDeparture, cursor.time),
        and(eq(flight.scheduledDeparture, cursor.time), gt(flight.flightId, cursor.id))
      )!
    );
  }

  return await query
    .where(and(...conditions))
    .orderBy(asc(flight.scheduledDeparture), asc(flight.flightId))
    .limit(100);
}

// HQ12: High-Volume Batch Upsert (2,500 Records with Conflict Resolution)
export async function hq12BatchUpsert(
  db: NodePgDatabase<any>,
  batch: Array<{
    flightId: number;
    status: string;
    actualDeparture: Date;
    actualArrival: Date;
    updateTs: Date;
    version: number;
  }>
) {
  return await db
    .insert(flightStatusUpdate)
    .values(batch)
    .onConflictDoUpdate({
      target: flightStatusUpdate.flightId,
      set: {
        status: sql`excluded.status`,
        actualDeparture: sql`excluded.actual_departure`,
        actualArrival: sql`excluded.actual_arrival`,
        updateTs: sql`excluded.update_ts`,
        version: sql`${flightStatusUpdate.version} + 1`,
      },
    });
}

// HQ13: Optimistic Concurrency Bulk Fare & Status Adjustment
export async function hq13OptimisticConcurrency(db: NodePgDatabase<any>) {
  return await db
    .update(flight)
    .set({
      status: 'Boarding',
      version: sql`${flight.version} + 1`,
      updateTs: sql`clock_timestamp()`,
    })
    .where(
      and(
        between(flight.flightId, 1000, 1050),
        eq(flight.version, 1)
      )
    );
}

// HQ14: High-Concurrency Seat Allocation Under Contention (C=100)
export async function hq14SeatAllocation(db: NodePgDatabase<any>, targetFlightId: number) {
  return await db.transaction(async (tx) => {
    const seats = await tx
      .select({
        flightId: flightSeatInventory.flightId,
        seatNo: flightSeatInventory.seatNo,
        version: flightSeatInventory.version,
      })
      .from(flightSeatInventory)
      .where(and(eq(flightSeatInventory.flightId, targetFlightId), eq(flightSeatInventory.status, 'AVAILABLE')))
      .orderBy(asc(flightSeatInventory.seatNo))
      .limit(1)
      .for('update');

    if (seats.length > 0) {
      const s = seats[0];
      await tx
        .update(flightSeatInventory)
        .set({
          status: 'RESERVED',
          passengerName: 'Test Concurrent Flyer',
          reservedAt: sql`clock_timestamp()`,
          version: sql`${flightSeatInventory.version} + 1`,
        })
        .where(
          and(
            eq(flightSeatInventory.flightId, s.flightId),
            eq(flightSeatInventory.seatNo, s.seatNo),
            eq(flightSeatInventory.version, s.version)
          )
        );
      return true;
    }
    return false;
  });
}

// HQ15: Distributed Financial / Points Transfer with 40001 Retry
export async function hq15PointsTransferWithRetry(
  db: NodePgDatabase<any>,
  fromId: number,
  toId: number,
  points: number
) {
  let retries = 5;
  let backoff = 10;
  while (retries >= 0) {
    try {
      await db.transaction(async (tx) => {
        await tx.execute(sql`SET TRANSACTION ISOLATION LEVEL SERIALIZABLE`);
        await tx
          .update(frequentFlyer)
          .set({ awardPoints: sql`${frequentFlyer.awardPoints} - ${points}` })
          .where(eq(frequentFlyer.frequentFlyerId, fromId));
        await tx
          .update(frequentFlyer)
          .set({ awardPoints: sql`${frequentFlyer.awardPoints} + ${points}` })
          .where(eq(frequentFlyer.frequentFlyerId, toId));
      });
      return;
    } catch (err: any) {
      if (err.code === '40001' && retries > 0) {
        retries--;
        await new Promise((r) => setTimeout(r, backoff));
        backoff *= 2;
        continue;
      }
      throw err;
    }
  }
}

// HQ16: Multi-Modal Hybrid Vector Similarity + BM25 RRF Search
export async function hq16HybridSearch(db: NodePgDatabase<any>) {
  const query = sql`
    WITH text_ranking AS (
        SELECT airport_code, 
               ROW_NUMBER() OVER (ORDER BY ts_rank_cd(search_tsv, plainto_tsquery('english', 'London Heathrow international hub')) DESC) AS rank_text
        FROM postgres_air.airport
        WHERE search_tsv @@ plainto_tsquery('english', 'London Heathrow international hub')
        LIMIT 25
    ),
    vector_ranking AS (
        SELECT airport_code, 
               ROW_NUMBER() OVER (ORDER BY (embedding <=> (SELECT embedding FROM postgres_air.airport WHERE airport_code = 'LHR')) ASC) AS rank_vec
        FROM postgres_air.airport
        LIMIT 25
    ),
    airport_stats AS (
        SELECT departure_airport AS airport_code,
               count(*) AS active_flights_count
        FROM postgres_air.flight
        WHERE scheduled_departure >= '2024-07-01 00:00:00+00' AND scheduled_departure < '2024-07-08 00:00:00+00'
        GROUP BY departure_airport
    )
    SELECT COALESCE(t.airport_code, v.airport_code) AS airport_code,
           a.airport_name, 
           a.city,
           COALESCE(ast.active_flights_count, 0) AS active_flights_count,
           round((COALESCE(1.0 / (60 + t.rank_text), 0.0) + COALESCE(1.0 / (60 + v.rank_vec), 0.0))::numeric, 5) AS rrf_score
    FROM text_ranking t
    FULL OUTER JOIN vector_ranking v ON t.airport_code = v.airport_code
    JOIN postgres_air.airport a ON a.airport_code = COALESCE(t.airport_code, v.airport_code)
    LEFT JOIN airport_stats ast ON ast.airport_code = COALESCE(t.airport_code, v.airport_code)
    ORDER BY rrf_score DESC
    LIMIT 25;
  `;
  const res = await db.execute(query);
  return res.rows;
}
