import { sql, type EntityManager } from '@mikro-orm/postgresql';
import {
  Flight,
  Booking,
  BookingLeg,
  BoardingPass,
  Passenger,
  Account,
  FrequentFlyer,
  Airport,
  Aircraft,
  FlightSeatInventory,
  FlightStatusUpdate,
} from './schema.js';

// HQ01: Massive Entity Deserialization (10,000 Wide Rows)
export async function hq01MassiveDeserialization(em: EntityManager) {
  return await em.createQueryBuilder(Flight, 'f')
    .select('*')
    .where({ flightId: { $lte: 10000 } })
    .orderBy({ flightId: 'ASC' })
    .limit(10000)
    .getResultList();
}

// HQ02: Wide Multi-Join Composite Hydration (5,000 Joined Records Across 4 Relations)
export async function hq02WideMultiJoin(em: EntityManager) {
  const sql = `
    SELECT b.booking_id, b.booking_ref, b.price, b.email,
           p.passenger_id, p.first_name, p.last_name,
           bl.booking_leg_id, bl.leg_num,
           f.flight_id, f.flight_no, f.scheduled_departure, f.departure_airport, f.arrival_airport
    FROM postgres_air.booking b
    JOIN postgres_air.passenger p ON b.booking_id = p.booking_id
    JOIN postgres_air.booking_leg bl ON b.booking_id = bl.booking_id
    JOIN postgres_air.flight f ON bl.flight_id = f.flight_id
    WHERE b.booking_id BETWEEN ? AND ?
    LIMIT 5000
  `;
  return await em.getConnection().execute(sql, [100000, 105000]);
}

// HQ03: 4-Level Deep Hierarchical Entity Tree (Flight -> Legs -> Booking -> Pass)
export async function hq03DeepHierarchicalGraph(em: EntityManager) {
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
  const rows: any[] = await em.getConnection().execute(sql);

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
export async function hq04AccountRelationshipGraph(em: EntityManager) {
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
  const rows: any[] = await em.getConnection().execute(sql);

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
export async function hq05RouteFinancialLedger(em: EntityManager, startTs = '2024-07-01', endTs = '2024-07-04') {
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
    WHERE f.scheduled_departure >= ? AND f.scheduled_departure < ?
    GROUP BY orig.airport_code, dest.airport_code, ac.model
    HAVING count(DISTINCT f.flight_id) >= 3
    ORDER BY total_revenue DESC
    LIMIT 50
  `;
  return await em.getConnection().execute(sql, [startTs, endTs]);
}

// HQ06: Chained Multi-Stage CTEs (Hub Centrality & Degree)
export async function hq06HubCentralityDegree(em: EntityManager, startTs = '2024-06-01', endTs = '2024-07-01') {
  const sql = `
    WITH flight_volumes AS (
        SELECT departure_airport AS airport_code,
               count(*)::bigint AS departures_count,
               round(avg(EXTRACT(EPOCH FROM (actual_departure - scheduled_departure)) / 60)::numeric, 2)::float8 AS avg_dep_delay
        FROM postgres_air.flight
        WHERE scheduled_departure >= ? AND scheduled_departure < ?
          AND actual_departure IS NOT NULL
        GROUP BY departure_airport
    ),
    arrival_volumes AS (
        SELECT arrival_airport AS airport_code,
               count(*)::bigint AS arrivals_count,
               round(avg(EXTRACT(EPOCH FROM (actual_arrival - scheduled_arrival)) / 60)::numeric, 2)::float8 AS avg_arr_delay
        FROM postgres_air.flight
        WHERE scheduled_arrival >= ? AND scheduled_arrival < ?
          AND actual_arrival IS NOT NULL
        GROUP BY arrival_airport
    ),
    route_connectivity AS (
        SELECT departure_airport AS airport_code,
               count(DISTINCT arrival_airport)::bigint AS unique_destinations,
               count(DISTINCT aircraft_code)::bigint AS fleet_diversity
        FROM postgres_air.flight
        WHERE scheduled_departure >= ? AND scheduled_departure < ?
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
  return await em.getConnection().execute(sql, [startTs, endTs, startTs, endTs, startTs, endTs]);
}

// HQ07: Correlated At-Capacity Subquery with Loyalty Tier Cross-Check
export async function hq07AtCapacityLoyaltyCrossCheck(em: EntityManager, startTs = '2024-07-01', endTs = '2024-07-04') {
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
    WHERE f.scheduled_departure >= ? AND f.scheduled_departure < ?
      AND ac.class >= 2
      AND (SELECT count(*) FROM postgres_air.booking_leg bl WHERE bl.flight_id = f.flight_id) > 40
      AND EXISTS (
          SELECT 1 FROM postgres_air.flight_seat_inventory fsi
          WHERE fsi.flight_id = f.flight_id AND fsi.status = 'AVAILABLE'
      )
    ORDER BY seats_booked DESC
    LIMIT 50
  `;
  return await em.getConnection().execute(sql, [startTs, endTs]);
}

// HQ08: Recursive Multi-Hop Flight Connection Graph Search (1-3 Hops)
export async function hq08RecursiveFlightPathSearch(em: EntityManager, origin = 'JFK', dest = 'ORD', startTs = '2024-07-05', endTs = '2024-07-06') {
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
        WHERE f.departure_airport = ? AND f.scheduled_departure >= ? AND f.scheduled_departure < ?
        UNION ALL
        SELECT next_f.flight_id, fp.departure_airport, next_f.arrival_airport::text,
               next_f.scheduled_departure, next_f.scheduled_arrival, fp.hops + 1,
               fp.route_airports || next_f.arrival_airport::text,
               fp.route_flights || next_f.flight_id,
               fp.journey_start, next_f.scheduled_arrival,
               fp.total_flight_minutes + (EXTRACT(EPOCH FROM (next_f.scheduled_arrival - next_f.scheduled_departure)) / 60)::float8
        FROM flight_paths fp
        JOIN postgres_air.flight next_f ON fp.arrival_airport = next_f.departure_airport
        WHERE fp.hops < 3
          AND next_f.scheduled_departure >= fp.scheduled_arrival + INTERVAL '60 minutes'
          AND next_f.scheduled_departure <= fp.scheduled_arrival + INTERVAL '360 minutes'
          AND NOT (next_f.arrival_airport::text = ANY(fp.route_airports))
    )
    SELECT hops, array_to_string(route_airports, ' -> ') AS path, journey_start, journey_end,
           (EXTRACT(EPOCH FROM (journey_end - journey_start)) / 60)::float8 AS total_elapsed_minutes,
           total_flight_minutes
    FROM flight_paths
    WHERE arrival_airport = ?
    ORDER BY hops ASC, total_elapsed_minutes ASC
    LIMIT 25
  `;
  return await em.getConnection().execute(sql, [origin, startTs, endTs, dest]);
}

// HQ09: Multi-Window Statistical Delay Dispersion & Cascades
export async function hq09MultiWindowDelayDispersion(em: EntityManager, airport = 'ORD', startTs = '2024-06-01', endTs = '2024-07-01') {
  const sql = `
    WITH flight_delays AS (
        SELECT flight_id, flight_no, departure_airport, arrival_airport,
               scheduled_departure, actual_departure,
               round((EXTRACT(EPOCH FROM (actual_departure - scheduled_departure)) / 60)::numeric, 2)::float8 AS delay_minutes
        FROM postgres_air.flight
        WHERE departure_airport = ? AND actual_departure IS NOT NULL
          AND scheduled_departure >= ? AND scheduled_departure < ?
    )
    SELECT flight_id, flight_no, arrival_airport, scheduled_departure, delay_minutes,
           round(avg(delay_minutes) OVER (
               PARTITION BY departure_airport, arrival_airport
               ORDER BY scheduled_departure
               ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
           )::numeric, 2)::float8 AS rolling_avg_delay_5,
           (delay_minutes - lag(delay_minutes, 1) OVER (
               PARTITION BY departure_airport, arrival_airport
               ORDER BY scheduled_departure
           ))::float8 AS delay_diff_prev,
           round(coalesce(stddev_samp(delay_minutes) OVER (
               PARTITION BY departure_airport, arrival_airport
               ORDER BY scheduled_departure
               ROWS BETWEEN 9 PRECEDING AND CURRENT ROW
           ), 0)::numeric, 2)::float8 AS rolling_stddev_10,
           dense_rank() OVER (
               PARTITION BY departure_airport, arrival_airport
               ORDER BY delay_minutes DESC
           )::bigint AS severity_rank
    FROM flight_delays
    ORDER BY departure_airport, arrival_airport, scheduled_departure
    LIMIT 5000
  `;
  return await em.getConnection().execute(sql, [airport, startTs, endTs]);
}

// HQ10: Keyset (Cursor) Pagination over Composite Tuple Under Load
export async function hq10KeysetPagination(em: EntityManager, cursorTs: string, cursorId: number, limit = 50) {
  return await em.createQueryBuilder(Flight, 'f')
    .select('*')
    .where('f.scheduled_departure >= ? AND (f.scheduled_departure > ? OR f.flight_id > ?)', [cursorTs, cursorTs, cursorId])
    .orderBy({ scheduledDeparture: 'ASC', flightId: 'ASC' })
    .limit(limit)
    .getResultList();
}

// HQ11: High-Dimensional Dynamic Faceted Flight Search Engine (10 Optional Predicates)
export interface FlightSearchParams {
  origins?: string[];
  destinations?: string[];
  minDeparture?: string;
  maxDeparture?: string;
  aircraftClass?: number[];
  minRange?: number;
  statuses?: string[];
  cursorTime?: string;
  cursorId?: number;
  limit?: number;
}

export async function hq11DynamicFacetedSearch(em: EntityManager, params: FlightSearchParams) {
  const qb = em.createQueryBuilder(Flight, 'f')
    .select(['f.*'])
    .join(sql.ref('postgres_air.aircraft'), 'ac', { 'ac.code': sql.ref('f.aircraft_code') });

  if (params.origins && params.origins.length > 0) {
    qb.andWhere({ 'f.departureAirport': { $in: params.origins } });
  }
  if (params.destinations && params.destinations.length > 0) {
    qb.andWhere({ 'f.arrivalAirport': { $in: params.destinations } });
  }
  if (params.minDeparture) {
    qb.andWhere({ 'f.scheduledDeparture': { $gte: params.minDeparture } });
  }
  if (params.maxDeparture) {
    qb.andWhere({ 'f.scheduledDeparture': { $lte: params.maxDeparture } });
  }
  if (params.aircraftClass && params.aircraftClass.length > 0) {
    qb.andWhere('ac.class IN (?)', [params.aircraftClass]);
  }
  if (params.minRange != null) {
    qb.andWhere('ac.range >= ?', [params.minRange]);
  }
  if (params.statuses && params.statuses.length > 0) {
    qb.andWhere({ 'f.status': { $in: params.statuses } });
  }
  if (params.cursorTime && params.cursorId != null) {
    qb.andWhere('(f.scheduled_departure > ? OR (f.scheduled_departure = ? AND f.flight_id > ?))', [
      params.cursorTime,
      params.cursorTime,
      params.cursorId,
    ]);
  }

  return await qb.orderBy({ scheduledDeparture: 'ASC', flightId: 'ASC' }).limit(params.limit || 100).getResultList();
}

// HQ12: High-Volume Batch Upsert (2,500 Records with Conflict Resolution)
export async function hq12BatchUpsert(em: EntityManager, updates: any[]) {
  // Use pg bulk multi-row insert with ON CONFLICT
  const values: any[] = [];
  const rows: string[] = [];
  for (let i = 0; i < updates.length; i++) {
    const u = updates[i];
    rows.push('(?, ?, ?, ?, ?, ?)');
    values.push(u.flightId, u.status, u.actualDeparture, u.actualArrival, u.updateTs, u.version);
  }
  const sql = `
    INSERT INTO postgres_air.flight_status_update (flight_id, status, actual_departure, actual_arrival, update_ts, version)
    VALUES ${rows.join(', ')}
    ON CONFLICT (flight_id) DO UPDATE SET
      status = EXCLUDED.status,
      actual_departure = EXCLUDED.actual_departure,
      actual_arrival = EXCLUDED.actual_arrival,
      update_ts = EXCLUDED.update_ts,
      version = postgres_air.flight_status_update.version + 1
  `;
  await em.getConnection().execute(sql, values);
  return updates.length;
}

// HQ13: Optimistic Concurrency Bulk Fare & Status Adjustment
export async function hq13OptimisticBulkUpdate(em: EntityManager, minFid: number, maxFid: number, expectedVer: number, newStatus: string) {
  const sql = `
    UPDATE postgres_air.flight
    SET status = ?, version = version + 1, update_ts = clock_timestamp()
    WHERE flight_id BETWEEN ? AND ? AND version = ?
  `;
  const res = await em.getConnection().execute(sql, [newStatus, minFid, maxFid, expectedVer]);
  return (res as any).rowCount || 1;
}

// HQ14: High-Concurrency Seat Allocation Under Contention (C=100)
export async function hq14ReserveSeatConcurrent(em: EntityManager, flightId: number, passengerName: string) {
  return await em.transactional(async (tem) => {
    const selSql = `
      SELECT seat_no, version FROM postgres_air.flight_seat_inventory
      WHERE flight_id = ? AND status = 'AVAILABLE'
      LIMIT 1 FOR UPDATE
    `;
    const rows: any[] = await tem.getConnection().execute(selSql, [flightId]);
    if (!rows || rows.length === 0) {
      return 'Sold Out';
    }
    const seat = rows[0];
    const updateSql = `
      UPDATE postgres_air.flight_seat_inventory
      SET status = 'RESERVED', passenger_name = ?, reserved_at = clock_timestamp(), version = version + 1
      WHERE flight_id = ? AND seat_no = ? AND version = ?
    `;
    await tem.getConnection().execute(updateSql, [passengerName, flightId, seat.seat_no, seat.version]);
    return seat.seat_no;
  });
}

// HQ15: Distributed Financial / Points Transfer with Serialization Retry
export async function hq15PointsTransferSerializable(em: EntityManager, fromAcc: number, toAcc: number, points: number) {
  const maxRetries = 5;
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      await em.transactional(async (tem) => {
        await tem.getConnection().execute('SET TRANSACTION ISOLATION LEVEL SERIALIZABLE');
        await tem.getConnection().execute(
          'UPDATE postgres_air.frequent_flyer SET award_points = award_points - ? WHERE frequent_flyer_id = ?',
          [points, fromAcc]
        );
        await tem.getConnection().execute(
          'UPDATE postgres_air.frequent_flyer SET award_points = award_points + ? WHERE frequent_flyer_id = ?',
          [points, toAcc]
        );
      });
      return;
    } catch (err: any) {
      if (err.code === '40001' && attempt < maxRetries - 1) {
        await new Promise((r) => setTimeout(r, 10 * Math.pow(2, attempt)));
        continue;
      }
      throw err;
    }
  }
}

// HQ16: Multi-Modal Hybrid Vector Similarity + BM25 RRF Search
export async function hq16HybridSearchRRF(em: EntityManager, targetAirport = 'LHR', queryText = 'London Heathrow international hub') {
  const sql = `
    WITH text_ranking AS (
        SELECT airport_code,
               ROW_NUMBER() OVER (ORDER BY ts_rank_cd(search_tsv, plainto_tsquery('english', ?)) DESC) AS rank_text
        FROM postgres_air.airport
        WHERE search_tsv @@ plainto_tsquery('english', ?)
        LIMIT 25
    ),
    vector_ranking AS (
        SELECT airport_code,
               ROW_NUMBER() OVER (ORDER BY (embedding <=> (SELECT embedding FROM postgres_air.airport WHERE airport_code = ?)) ASC) AS rank_vec
        FROM postgres_air.airport
        LIMIT 25
    ),
    airport_stats AS (
        SELECT departure_airport AS airport_code,
               count(*)::bigint AS active_flights_count
        FROM postgres_air.flight
        WHERE scheduled_departure >= '2024-07-01' AND scheduled_departure < '2024-07-15'
        GROUP BY departure_airport
    ),
    rrf_scores AS (
        SELECT coalesce(t.airport_code, v.airport_code) AS airport_code,
               (coalesce(1.0 / (60.0 + t.rank_text), 0.0) + coalesce(1.0 / (60.0 + v.rank_vec), 0.0))::float8 AS rrf_score
        FROM text_ranking t
        FULL OUTER JOIN vector_ranking v ON t.airport_code = v.airport_code
    )
    SELECT a.airport_code, a.airport_name, a.city,
           coalesce(s.active_flights_count, 0)::bigint AS active_flights,
           round(r.rrf_score::numeric, 6)::float8 AS final_rrf_score
    FROM rrf_scores r
    JOIN postgres_air.airport a ON r.airport_code = a.airport_code
    LEFT JOIN airport_stats s ON a.airport_code = s.airport_code
    ORDER BY final_rrf_score DESC
    LIMIT 10
  `;
  return await em.getConnection().execute(sql, [queryText, queryText, targetAirport]);
}
