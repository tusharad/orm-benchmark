import { DataSource } from "typeorm";
import {
  Flight,
  Aircraft,
  Airport,
  Account,
  FrequentFlyer,
  Booking,
  BookingLeg,
  BoardingPass,
  Passenger,
  FlightSeatInventory,
  FlightStatusUpdate
} from "./schema.js";

export interface FlightSearchParams {
  origins?: string[];
  destinations?: string[];
  minDeparture?: Date;
  maxDeparture?: Date;
  aircraftClasses?: number[];
  minRange?: number;
  statuses?: string[];
  cursor?: { scheduledDeparture: Date; flightId: number };
  limit?: number;
}

// HQ01: Massive Entity Deserialization (10,000 Wide Rows)
export async function hq01MassiveDeserialization(ds: DataSource): Promise<Flight[]> {
  return await ds.getRepository(Flight)
    .createQueryBuilder("f")
    .orderBy("f.flightId", "ASC")
    .limit(10000)
    .getMany();
}

// HQ02: Wide Multi-Join Composite Hydration (5,000 Joined Records Across 4 Relations)
export async function hq02WideMultiJoin(ds: DataSource) {
  const sql = `
    SELECT b.booking_id, b.booking_ref, b.price, b.email,
           p.passenger_id, p.first_name, p.last_name,
           bl.booking_leg_id, bl.leg_num,
           f.flight_id, f.flight_no, f.scheduled_departure, f.departure_airport, f.arrival_airport
    FROM postgres_air.booking b
    JOIN postgres_air.passenger p ON b.booking_id = p.booking_id
    JOIN postgres_air.booking_leg bl ON b.booking_id = bl.booking_id
    JOIN postgres_air.flight f ON bl.flight_id = f.flight_id
    WHERE b.booking_id BETWEEN $1 AND $2
    LIMIT 5000
  `;
  return await ds.query(sql, [100000, 105000]);
}

// HQ03: 4-Level Deep Hierarchical Entity Tree (Flight -> Legs -> Booking -> Pass)
export async function hq03DeepHierarchicalGraph(ds: DataSource) {
  const sql = `
    SELECT f.flight_id, f.flight_no, f.scheduled_departure,
           bl.booking_leg_id, bl.leg_num,
           b.booking_id, b.booking_ref, b.email,
           bp.pass_id, bp.seat, bp.boarding_time
    FROM postgres_air.flight f
    JOIN postgres_air.booking_leg bl ON f.flight_id = bl.flight_id
    JOIN postgres_air.booking b ON bl.booking_id = b.booking_id
    LEFT JOIN postgres_air.boarding_pass bp ON bl.booking_leg_id = bp.booking_leg_id
    WHERE f.flight_id BETWEEN 2000 AND 2025
    ORDER BY f.flight_id, bl.booking_leg_id
  `;
  const rows = await ds.query(sql);

  const flightMap = new Map<number, any>();
  for (const row of rows) {
    let f = flightMap.get(row.flight_id);
    if (!f) {
      f = {
        flightId: row.flight_id,
        flightNo: row.flight_no,
        scheduledDeparture: row.scheduled_departure,
        legs: []
      };
      flightMap.set(row.flight_id, f);
    }
    f.legs.push({
      bookingLegId: row.booking_leg_id,
      legNum: row.leg_num,
      booking: {
        bookingId: row.booking_id,
        bookingRef: row.booking_ref,
        email: row.email
      },
      boardingPass: row.pass_id ? {
        passId: row.pass_id,
        seat: row.seat,
        boardingTime: row.boarding_time
      } : null
    });
  }
  return Array.from(flightMap.values());
}

// HQ04: Account Relationship Graph with Optional Sub-Entities
export async function hq04AccountRelationshipGraph(ds: DataSource) {
  const sql = `
    SELECT a.account_id, a.login, a.first_name, a.last_name,
           ff.frequent_flyer_id, ff.level, ff.award_points,
           b.booking_id, b.email,
           p.passenger_id, p.first_name as pass_first, p.last_name as pass_last
    FROM postgres_air.account a
    LEFT JOIN postgres_air.frequent_flyer ff ON a.frequent_flyer_id = ff.frequent_flyer_id
    LEFT JOIN postgres_air.booking b ON a.account_id = b.account_id
    LEFT JOIN postgres_air.passenger p ON b.booking_id = p.booking_id
    WHERE a.account_id BETWEEN 1000 AND 1050
    ORDER BY a.account_id
  `;
  const rows = await ds.query(sql);

  const accMap = new Map<number, any>();
  for (const row of rows) {
    let acc = accMap.get(row.account_id);
    if (!acc) {
      acc = {
        accountId: row.account_id,
        login: row.login,
        name: `${row.first_name} ${row.last_name}`,
        frequentFlyer: row.frequent_flyer_id ? {
          id: row.frequent_flyer_id,
          level: row.level,
          points: row.award_points
        } : null,
        bookings: []
      };
      accMap.set(row.account_id, acc);
    }
    if (row.booking_id) {
      acc.bookings.push({
        bookingId: row.booking_id,
        email: row.email,
        passenger: row.passenger_id ? {
          id: row.passenger_id,
          name: `${row.pass_first} ${row.pass_last}`
        } : null
      });
    }
  }
  return Array.from(accMap.values());
}

// HQ05: Fleet & Route Profitability Analytical Ledger (5 Tables, 400k+ Rows)
export async function hq05RouteFinancialLedger(ds: DataSource, startTs = '2024-07-01', endTs = '2024-07-04') {
  const sql = `
    SELECT orig.airport_code AS origin,
           dest.airport_code AS destination,
           ac.model,
           count(DISTINCT f.flight_id)::bigint AS total_flights,
           count(bl.booking_leg_id)::bigint AS total_legs,
           round(sum(b.price), 2)::float8 AS total_revenue,
           round(avg(EXTRACT(EPOCH FROM (f.actual_departure - f.scheduled_departure)) / 60)::numeric, 2)::float8 AS avg_delay_min,
           round(100.0 * count(CASE WHEN f.actual_departure <= f.scheduled_departure + INTERVAL '15 minutes' THEN 1 END) / count(f.flight_id), 2)::float8 AS on_time_pct
    FROM postgres_air.flight f
    JOIN postgres_air.airport orig ON f.departure_airport = orig.airport_code
    JOIN postgres_air.airport dest ON f.arrival_airport = dest.airport_code
    JOIN postgres_air.aircraft ac ON f.aircraft_code = ac.code
    JOIN postgres_air.booking_leg bl ON f.flight_id = bl.flight_id
    JOIN postgres_air.booking b ON bl.booking_id = b.booking_id
    WHERE f.scheduled_departure >= $1 AND f.scheduled_departure < $2
    GROUP BY orig.airport_code, dest.airport_code, ac.model
    HAVING count(DISTINCT f.flight_id) >= 3
    ORDER BY total_revenue DESC
    LIMIT 50
  `;
  return await ds.query(sql, [startTs, endTs]);
}

// HQ06: Chained Multi-Stage CTEs (Hub Centrality & Degree)
export async function hq06HubCentralityDegree(ds: DataSource, startTs = '2024-06-01', endTs = '2024-07-01') {
  const sql = `
    WITH flight_volumes AS (
        SELECT departure_airport AS airport_code,
               count(*)::bigint AS departures_count,
               round(avg(EXTRACT(EPOCH FROM (actual_departure - scheduled_departure)) / 60)::numeric, 2)::float8 AS avg_dep_delay
        FROM postgres_air.flight
        WHERE scheduled_departure >= $1 AND scheduled_departure < $2
          AND actual_departure IS NOT NULL
        GROUP BY departure_airport
    ),
    arrival_volumes AS (
        SELECT arrival_airport AS airport_code,
               count(*)::bigint AS arrivals_count,
               round(avg(EXTRACT(EPOCH FROM (actual_arrival - scheduled_arrival)) / 60)::numeric, 2)::float8 AS avg_arr_delay
        FROM postgres_air.flight
        WHERE scheduled_arrival >= $3 AND scheduled_arrival < $4
          AND actual_arrival IS NOT NULL
        GROUP BY arrival_airport
    ),
    route_connectivity AS (
        SELECT departure_airport AS airport_code,
               count(DISTINCT arrival_airport)::bigint AS unique_destinations,
               count(DISTINCT aircraft_code)::bigint AS fleet_diversity
        FROM postgres_air.flight
        WHERE scheduled_departure >= $5 AND scheduled_departure < $6
        GROUP BY departure_airport
    )
    SELECT a.airport_code, a.airport_name, a.city,
           coalesce(fv.departures_count, 0)::bigint AS departures,
           coalesce(av.arrivals_count, 0)::bigint AS arrivals,
           coalesce(rc.unique_destinations, 0)::bigint AS destinations,
           coalesce(rc.fleet_diversity, 0)::bigint AS fleet_diversity,
           coalesce(fv.avg_dep_delay, 0)::float8 AS avg_dep_delay,
           coalesce(av.avg_arr_delay, 0)::float8 AS avg_arr_delay,
           round(
               ((coalesce(fv.departures_count, 0) + coalesce(av.arrivals_count, 0)) *
               (1.0 + coalesce(rc.unique_destinations, 0) / 100.0) /
               (1.0 + greatest(coalesce(fv.avg_dep_delay, 0), 0) / 10.0))::numeric,
               2
           )::float8 AS hub_centrality_score
    FROM postgres_air.airport a
    JOIN flight_volumes fv ON a.airport_code = fv.airport_code
    JOIN arrival_volumes av ON a.airport_code = av.airport_code
    JOIN route_connectivity rc ON a.airport_code = rc.airport_code
    ORDER BY hub_centrality_score DESC
    LIMIT 50
  `;
  return await ds.query(sql, [startTs, endTs, startTs, endTs, startTs, endTs]);
}

// HQ07: Correlated At-Capacity Subquery with Loyalty Tier Cross-Check
export async function hq07AtCapacityLoyaltyCrossCheck(ds: DataSource, startTs = '2024-07-01', endTs = '2024-07-04') {
  const sql = `
    SELECT f.flight_id, f.flight_no, f.departure_airport, f.arrival_airport,
           f.scheduled_departure, coalesce(ac.model, 'Unknown') as model,
           (SELECT count(*)::bigint FROM postgres_air.booking_leg bl WHERE bl.flight_id = f.flight_id) AS seats_booked,
           (SELECT count(*)::bigint FROM postgres_air.booking_leg bl
            JOIN postgres_air.passenger p ON bl.booking_id = p.booking_id
            JOIN postgres_air.account a ON p.account_id = a.account_id
            JOIN postgres_air.frequent_flyer ff ON a.frequent_flyer_id = ff.frequent_flyer_id
            WHERE bl.flight_id = f.flight_id AND ff.level >= 3) AS elite_flyer_count
    FROM postgres_air.flight f
    JOIN postgres_air.aircraft ac ON f.aircraft_code = ac.code
    WHERE f.scheduled_departure >= $1 AND f.scheduled_departure < $2
      AND ac.class >= 2
      AND (SELECT count(*) FROM postgres_air.booking_leg bl WHERE bl.flight_id = f.flight_id) > 40
      AND EXISTS (
          SELECT 1 FROM postgres_air.flight_seat_inventory fsi
          WHERE fsi.flight_id = f.flight_id AND fsi.status = 'AVAILABLE'
      )
    ORDER BY seats_booked DESC
    LIMIT 50
  `;
  return await ds.query(sql, [startTs, endTs]);
}

// HQ08: Recursive Multi-Hop Flight Connection Graph Search (1-3 Hops)
export async function hq08RecursiveFlightPathSearch(ds: DataSource, origin = 'JFK', dest = 'ORD', startTs = '2024-07-05', endTs = '2024-07-06') {
  const sql = `
    WITH RECURSIVE flight_paths AS (
        SELECT f.flight_id, f.departure_airport::text AS departure_airport,
               f.arrival_airport::text AS arrival_airport,
               f.scheduled_departure, f.scheduled_arrival, 1 AS hops,
               ARRAY[f.departure_airport::text, f.arrival_airport::text] AS route_airports,
               ARRAY[f.flight_id] AS route_flights,
               f.scheduled_departure AS journey_start, f.scheduled_arrival AS journey_end,
               (EXTRACT(EPOCH FROM (f.scheduled_arrival - f.scheduled_departure)) / 60)::float8 AS total_flight_minutes
        FROM postgres_air.flight f
        WHERE f.departure_airport = $1
          AND f.scheduled_departure >= $2 AND f.scheduled_departure < $3
        UNION ALL
        SELECT next_f.flight_id, next_f.departure_airport::text, next_f.arrival_airport::text,
               next_f.scheduled_departure, next_f.scheduled_arrival, fp.hops + 1,
               fp.route_airports || next_f.arrival_airport::text,
               fp.route_flights || next_f.flight_id,
               fp.journey_start, next_f.scheduled_arrival,
               (fp.total_flight_minutes + EXTRACT(EPOCH FROM (next_f.scheduled_arrival - next_f.scheduled_departure)) / 60)::float8
        FROM postgres_air.flight next_f
        JOIN flight_paths fp ON next_f.departure_airport = fp.arrival_airport
        WHERE fp.hops < 3
          AND next_f.scheduled_departure >= fp.scheduled_arrival + INTERVAL '45 minutes'
          AND next_f.scheduled_departure <= fp.scheduled_arrival + INTERVAL '6 hours'
          AND NOT (next_f.arrival_airport::text = ANY(fp.route_airports))
    )
    SELECT route_airports, hops, journey_start, journey_end, round(total_flight_minutes::numeric, 1)::float8 AS total_minutes
    FROM flight_paths
    WHERE arrival_airport = $4
    ORDER BY hops ASC, total_minutes ASC
    LIMIT 20
  `;
  return await ds.query(sql, [origin, startTs, endTs, dest]);
}

// HQ09: Multi-Window Statistical Delay Dispersion & Cascades
export async function hq09MultiWindowDelayDispersion(ds: DataSource, airport = 'ORD', startTs = '2024-06-01', endTs = '2024-07-01') {
  const sql = `
    SELECT flight_id, flight_no, scheduled_departure, actual_departure,
           coalesce(EXTRACT(EPOCH FROM (actual_departure - scheduled_departure)) / 60.0, 0.0)::float8 AS delay_minutes,
           avg(coalesce(EXTRACT(EPOCH FROM (actual_departure - scheduled_departure)) / 60.0, 0.0)) OVER (
               PARTITION BY departure_airport ORDER BY scheduled_departure ROWS BETWEEN 5 PRECEDING AND CURRENT ROW
           )::float8 AS moving_avg_delay,
           stddev(coalesce(EXTRACT(EPOCH FROM (actual_departure - scheduled_departure)) / 60.0, 0.0)) OVER (
               PARTITION BY departure_airport ORDER BY scheduled_departure ROWS BETWEEN 10 PRECEDING AND CURRENT ROW
           )::float8 AS stddev_delay,
           dense_rank() OVER (
               PARTITION BY departure_airport ORDER BY coalesce(EXTRACT(EPOCH FROM (actual_departure - scheduled_departure)), 0.0) DESC
           ) AS delay_severity_rank
    FROM postgres_air.flight
    WHERE departure_airport = $1
      AND scheduled_departure >= $2 AND scheduled_departure < $3
    ORDER BY scheduled_departure ASC
    LIMIT 100
  `;
  return await ds.query(sql, [airport, startTs, endTs]);
}

// HQ10: Keyset (Cursor) Pagination over Composite Tuple Under Concurrency
export async function hq10KeysetPagination(ds: DataSource, cursorTime: Date, cursorId: number, limit = 50): Promise<Flight[]> {
  return await ds.getRepository(Flight)
    .createQueryBuilder("f")
    .where("f.scheduledDeparture > :cursorTime OR (f.scheduledDeparture = :cursorTime AND f.flightId > :cursorId)", { cursorTime, cursorId })
    .orderBy("f.scheduledDeparture", "ASC")
    .addOrderBy("f.flightId", "ASC")
    .limit(limit)
    .getMany();
}

// HQ11: High-Dimensional Dynamic Faceted Flight Search Engine (10 Optional Predicates)
export async function hq11DynamicFacetedSearch(ds: DataSource, params: FlightSearchParams) {
  let qb = ds.getRepository(Flight).createQueryBuilder("f")
    .innerJoin(Aircraft, "ac", "f.aircraftCode = ac.code")
    .select([
      "f.flightId",
      "f.flightNo",
      "f.scheduledDeparture",
      "f.departureAirport",
      "f.arrivalAirport",
      "ac.model",
      "ac.class"
    ]);

  if (params.origins?.length) {
    qb = qb.andWhere("f.departureAirport IN (:...origins)", { origins: params.origins });
  }
  if (params.destinations?.length) {
    qb = qb.andWhere("f.arrivalAirport IN (:...destinations)", { destinations: params.destinations });
  }
  if (params.minDeparture) {
    qb = qb.andWhere("f.scheduledDeparture >= :minDep", { minDep: params.minDeparture });
  }
  if (params.maxDeparture) {
    qb = qb.andWhere("f.scheduledDeparture <= :maxDep", { maxDep: params.maxDeparture });
  }
  if (params.aircraftClasses?.length) {
    qb = qb.andWhere("ac.class IN (:...classes)", { classes: params.aircraftClasses });
  }
  if (params.minRange) {
    qb = qb.andWhere("ac.range >= :minRange", { minRange: params.minRange });
  }
  if (params.statuses?.length) {
    qb = qb.andWhere("f.status IN (:...statuses)", { statuses: params.statuses });
  }
  if (params.cursor) {
    qb = qb.andWhere("(f.scheduledDeparture > :cursorTime OR (f.scheduledDeparture = :cursorTime AND f.flightId > :cursorId))", {
      cursorTime: params.cursor.scheduledDeparture,
      cursorId: params.cursor.flightId
    });
  }
  return await qb.orderBy("f.scheduledDeparture", "ASC")
    .addOrderBy("f.flightId", "ASC")
    .limit(params.limit || 100)
    .getRawMany();
}

// HQ12: High-Volume Batch Upsert (2,500 Records with Conflict Resolution)
export async function hq12BatchUpsert(ds: DataSource, count: number = 2500) {
  const rows: any[] = [];
  const now = new Date();
  for (let i = 1; i <= count; i++) {
    rows.push({
      flightId: i,
      status: 'Departed',
      actualDeparture: now,
      actualArrival: now,
      updateTs: now,
      version: 1
    });
  }
  await ds.createQueryBuilder()
    .insert()
    .into(FlightStatusUpdate)
    .values(rows)
    .orUpdate(
      ['status', 'actual_departure', 'actual_arrival', 'update_ts'],
      ['flight_id']
    )
    .execute();
}

// HQ13: Optimistic Concurrency Bulk Fare & Status Adjustment
export async function hq13OptimisticBulkUpdate(ds: DataSource, minFid: number, maxFid: number, expectedVer: number, newStatus: string) {
  const res = await ds.createQueryBuilder()
    .update(Flight)
    .set({
      status: newStatus,
      version: () => "version + 1",
      updateTs: () => "clock_timestamp()"
    })
    .where("flightId BETWEEN :minFid AND :maxFid AND version = :expectedVer", { minFid, maxFid, expectedVer })
    .execute();
  return res.affected ?? 0;
}

// HQ14: High-Concurrency Seat Allocation Under Contention (C=100)
export async function hq14ReserveSeatConcurrent(ds: DataSource, flightId: number, passengerName: string) {
  return await ds.transaction(async (tx) => {
    const seat = await tx.createQueryBuilder(FlightSeatInventory, "s")
      .setLock("pessimistic_write")
      .where("s.flightId = :flightId AND s.status = 'AVAILABLE'", { flightId })
      .limit(1)
      .getOne();

    if (seat) {
      await tx.createQueryBuilder()
        .update(FlightSeatInventory)
        .set({
          status: 'RESERVED',
          passengerName: passengerName,
          reservedAt: new Date(),
          version: () => "version + 1"
        })
        .where("flightId = :flightId AND seatNo = :seatNo", { flightId, seatNo: seat.seatNo })
        .execute();
      return seat.seatNo;
    }
    return "NONE";
  });
}

// HQ15: Distributed Financial / Points Transfer with Serialization Retry
export async function hq15PointsTransferSerializable(ds: DataSource, fromAcc: number, toAcc: number, points: number) {
  for (let attempt = 0; attempt < 5; attempt++) {
    const qr = ds.createQueryRunner();
    await qr.connect();
    await qr.startTransaction("SERIALIZABLE");
    try {
      await qr.query("UPDATE postgres_air.frequent_flyer SET award_points = award_points - $1 WHERE frequent_flyer_id = $2", [points, fromAcc]);
      await qr.query("UPDATE postgres_air.frequent_flyer SET award_points = award_points + $1 WHERE frequent_flyer_id = $2", [points, toAcc]);
      await qr.commitTransaction();
      await qr.release();
      return;
    } catch (err: any) {
      await qr.rollbackTransaction();
      await qr.release();
      if (err.code === '40001' && attempt < 4) {
        await new Promise(r => setTimeout(r, 10 * Math.pow(2, attempt)));
        continue;
      }
      throw err;
    }
  }
}

// HQ16: Multi-Modal Hybrid Vector Similarity + BM25 RRF Search
export async function hq16HybridSearchRRF(ds: DataSource, targetAirport: string = 'LHR', queryText: string = 'London Heathrow international hub') {
  const sql = `
    WITH text_ranking AS (
        SELECT airport_code, ROW_NUMBER() OVER (ORDER BY ts_rank_cd(search_tsv, plainto_tsquery('english', $1)) DESC) AS rank_text
        FROM postgres_air.airport WHERE search_tsv @@ plainto_tsquery('english', $1) LIMIT 25
    ),
    vector_ranking AS (
        SELECT airport_code, ROW_NUMBER() OVER (ORDER BY (embedding <=> (SELECT embedding FROM postgres_air.airport WHERE airport_code = $2)) ASC) AS rank_vec
        FROM postgres_air.airport LIMIT 25
    ),
    airport_stats AS (
        SELECT departure_airport AS airport_code, count(*)::bigint AS active_flights_count
        FROM postgres_air.flight WHERE scheduled_departure >= '2024-07-01' AND scheduled_departure < '2024-07-15' GROUP BY departure_airport
    ),
    rrf_scores AS (
        SELECT coalesce(t.airport_code, v.airport_code) AS airport_code,
               (coalesce(1.0 / (60.0 + t.rank_text), 0.0) + coalesce(1.0 / (60.0 + v.rank_vec), 0.0))::float8 AS rrf_score
        FROM text_ranking t FULL OUTER JOIN vector_ranking v ON t.airport_code = v.airport_code
    )
    SELECT a.airport_code, a.airport_name, a.city, coalesce(s.active_flights_count, 0)::bigint AS active_flights, round(r.rrf_score::numeric, 6)::float8 AS final_rrf_score
    FROM rrf_scores r JOIN postgres_air.airport a ON r.airport_code = a.airport_code LEFT JOIN airport_stats s ON a.airport_code = s.airport_code
    ORDER BY final_rrf_score DESC LIMIT 10
  `;
  return await ds.query(sql, [queryText, targetAirport]);
}
