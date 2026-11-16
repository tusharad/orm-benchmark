import { PrismaClient, Prisma } from '@prisma/client';

export interface FlightSearchParams {
  origins?: string[];
  destinations?: string[];
  minDeparture?: Date;
  maxDeparture?: Date;
  aircraftClass?: number[];
  minRange?: number;
  statuses?: string[];
  cursorTime?: Date;
  cursorId?: number;
  limit?: number;
}

// HQ01: Massive Entity Deserialization (10k Wide Rows)
export async function hq01MassiveDeserialization(prisma: PrismaClient) {
  return await prisma.flight.findMany({
    take: 10000,
    orderBy: { flight_id: 'asc' },
  });
}

// HQ02: Wide Multi-Join Composite Hydration (5k Joined Rows)
export async function hq02WideMultiJoin(prisma: PrismaClient) {
  const sql = Prisma.sql`
    SELECT b.booking_id, b.booking_ref, b.email,
           p.passenger_id, p.first_name, p.last_name,
           bl.booking_leg_id, bl.leg_num,
           f.flight_id, f.flight_no, f.scheduled_departure, f.departure_airport, f.arrival_airport
    FROM postgres_air.booking b
    JOIN postgres_air.passenger p ON b.booking_id = p.booking_id
    JOIN postgres_air.booking_leg bl ON b.booking_id = bl.booking_id
    JOIN postgres_air.flight f ON bl.flight_id = f.flight_id
    WHERE b.booking_id BETWEEN 100000 AND 105000
    LIMIT 5000
  `;
  return await prisma.$queryRaw(sql);
}

// HQ03: 4-Level Deep Entity Tree (Flight -> Legs -> Booking -> Pass)
export async function hq03DeepHierarchicalGraph(prisma: PrismaClient) {
  return await prisma.flight.findMany({
    where: {
      flight_id: { gte: 2000, lte: 2025 },
    },
    include: {
      booking_leg: {
        include: {
          booking: true,
          boarding_pass: true,
        },
      },
    },
    orderBy: { flight_id: 'asc' },
  });
}

// HQ04: Account Relationship Graph with Optional Sub-Entities
export async function hq04AccountRelationshipGraph(prisma: PrismaClient) {
  return await prisma.account.findMany({
    where: {
      account_id: { gte: 1000, lte: 1050 },
    },
    include: {
      frequent_flyer: true,
      phone: true,
      booking: {
        include: {
          passenger: true,
        },
      },
    },
    orderBy: { account_id: 'asc' },
  });
}

// HQ05: Fleet & Route Profitability Ledger (5 Tables, 400k+ Rows)
export async function hq05RouteFinancialLedger(prisma: PrismaClient, startDate = '2024-07-01', endDate = '2024-07-04') {
  const sql = Prisma.sql`
    SELECT f.flight_no,
           f.departure_airport,
           f.arrival_airport,
           ac.model AS aircraft_model,
           count(DISTINCT f.flight_id) AS total_flights,
           count(DISTINCT b.booking_id) AS total_bookings,
           count(p.passenger_id) AS total_passengers,
           coalesce(sum(b.price), 0.0)::float8 AS gross_revenue,
           round(avg(b.price), 2)::float8 AS avg_ticket_price
    FROM postgres_air.flight f
    JOIN postgres_air.aircraft ac ON f.aircraft_code = ac.code
    JOIN postgres_air.booking_leg bl ON f.flight_id = bl.flight_id
    JOIN postgres_air.booking b ON bl.booking_id = b.booking_id
    LEFT JOIN postgres_air.passenger p ON b.booking_id = p.booking_id
    WHERE f.scheduled_departure >= ${startDate}::timestamptz 
      AND f.scheduled_departure < ${endDate}::timestamptz
    GROUP BY f.flight_no, f.departure_airport, f.arrival_airport, ac.model
    ORDER BY gross_revenue DESC, total_passengers DESC
    LIMIT 100
  `;
  return await prisma.$queryRaw(sql);
}

// HQ06: Chained Multi-Stage CTEs (Hub Centrality & Degree)
export async function hq06HubCentralityDegree(prisma: PrismaClient, startDate = '2024-06-01', endDate = '2024-07-01') {
  const sql = Prisma.sql`
    WITH flight_nodes AS (
        SELECT departure_airport AS hub,
               arrival_airport AS spoke,
               count(*)::int AS outbound_flights
        FROM postgres_air.flight
        WHERE scheduled_departure >= ${startDate}::timestamptz 
          AND scheduled_departure < ${endDate}::timestamptz
        GROUP BY departure_airport, arrival_airport
    ),
    hub_metrics AS (
        SELECT hub,
               count(DISTINCT spoke)::int AS degree_out,
               sum(outbound_flights)::bigint AS total_departures
        FROM flight_nodes
        GROUP BY hub
    ),
    ranked_hubs AS (
        SELECT hub,
               degree_out,
               total_departures,
               dense_rank() OVER (ORDER BY total_departures DESC) AS departure_rank,
               dense_rank() OVER (ORDER BY degree_out DESC) AS connectivity_rank
        FROM hub_metrics
    )
    SELECT hub, degree_out, total_departures, departure_rank, connectivity_rank
    FROM ranked_hubs
    WHERE departure_rank <= 20 OR connectivity_rank <= 20
    ORDER BY departure_rank ASC
  `;
  return await prisma.$queryRaw(sql);
}

// HQ07: Correlated At-Capacity Subquery + Loyalty Cross-Check
export async function hq07AtCapacityLoyaltyCrossCheck(prisma: PrismaClient, startDate = '2024-07-01', endDate = '2024-07-04') {
  const sql = Prisma.sql`
    SELECT f.flight_id,
           f.flight_no,
           f.scheduled_departure,
           (SELECT count(*)::int FROM postgres_air.booking_leg bl WHERE bl.flight_id = f.flight_id) AS current_load,
           (SELECT avg(ff.award_points)::float8
            FROM postgres_air.booking_leg bl2
            JOIN postgres_air.passenger p ON bl2.booking_id = p.booking_id
            JOIN postgres_air.account a ON p.account_id = a.account_id
            JOIN postgres_air.frequent_flyer ff ON a.frequent_flyer_id = ff.frequent_flyer_id
            WHERE bl2.flight_id = f.flight_id) AS avg_vip_points
    FROM postgres_air.flight f
    WHERE f.scheduled_departure >= ${startDate}::timestamptz 
      AND f.scheduled_departure < ${endDate}::timestamptz
      AND (
          SELECT count(*) FROM postgres_air.booking_leg bl3 WHERE bl3.flight_id = f.flight_id
      ) > 20
    ORDER BY current_load DESC
    LIMIT 50
  `;
  return await prisma.$queryRaw(sql);
}

// HQ08: Recursive Multi-Hop Flight Connection Graph (1-3 Hops)
export async function hq08RecursiveFlightPathSearch(prisma: PrismaClient, origin = 'JFK', dest = 'ORD', startDate = '2024-07-05', endDate = '2024-07-06') {
  const sql = Prisma.sql`
    WITH RECURSIVE flight_itinerary AS (
        SELECT flight_id,
               flight_no,
               departure_airport,
               arrival_airport,
               scheduled_departure,
               scheduled_arrival,
               1 AS hops,
               ARRAY[departure_airport, arrival_airport]::text[] AS route
        FROM postgres_air.flight
        WHERE departure_airport = ${origin}
          AND scheduled_departure >= ${startDate}::timestamptz 
          AND scheduled_departure < ${endDate}::timestamptz

        UNION ALL

        SELECT next_f.flight_id,
               next_f.flight_no,
               next_f.departure_airport,
               next_f.arrival_airport,
               next_f.scheduled_departure,
               next_f.scheduled_arrival,
               fi.hops + 1,
               fi.route || next_f.arrival_airport::text
        FROM postgres_air.flight next_f
        JOIN flight_itinerary fi ON next_f.departure_airport = fi.arrival_airport
        WHERE next_f.scheduled_departure >= fi.scheduled_arrival + INTERVAL '1 hour'
          AND next_f.scheduled_departure <= fi.scheduled_arrival + INTERVAL '6 hours'
          AND fi.hops < 3
          AND NOT (next_f.arrival_airport = ANY(fi.route))
    )
    SELECT route, hops, scheduled_departure, scheduled_arrival
    FROM flight_itinerary
    WHERE arrival_airport = ${dest}
    ORDER BY hops ASC, scheduled_arrival ASC
    LIMIT 20
  `;
  return await prisma.$queryRaw(sql);
}

// HQ09: Multi-Window Statistical Delay Dispersion & Cascades
export async function hq09MultiWindowDelayDispersion(prisma: PrismaClient, airport = 'ORD', startDate = '2024-06-01', endDate = '2024-07-01') {
  const sql = Prisma.sql`
    SELECT flight_id,
           flight_no,
           scheduled_departure,
           actual_departure,
           coalesce(EXTRACT(EPOCH FROM (actual_departure - scheduled_departure)) / 60.0, 0.0)::float8 AS delay_minutes,
           avg(coalesce(EXTRACT(EPOCH FROM (actual_departure - scheduled_departure)) / 60.0, 0.0)) OVER (
               PARTITION BY departure_airport 
               ORDER BY scheduled_departure 
               ROWS BETWEEN 5 PRECEDING AND CURRENT ROW
           )::float8 AS moving_avg_delay,
           stddev(coalesce(EXTRACT(EPOCH FROM (actual_departure - scheduled_departure)) / 60.0, 0.0)) OVER (
               PARTITION BY departure_airport 
               ORDER BY scheduled_departure 
               ROWS BETWEEN 10 PRECEDING AND CURRENT ROW
           )::float8 AS stddev_delay,
           dense_rank() OVER (
               PARTITION BY departure_airport 
               ORDER BY coalesce(EXTRACT(EPOCH FROM (actual_departure - scheduled_departure)), 0.0) DESC
           ) AS delay_severity_rank
    FROM postgres_air.flight
    WHERE departure_airport = ${airport}
      AND scheduled_departure >= ${startDate}::timestamptz 
      AND scheduled_departure < ${endDate}::timestamptz
    ORDER BY scheduled_departure ASC
    LIMIT 100
  `;
  return await prisma.$queryRaw(sql);
}

// HQ10: Keyset (Cursor) Pagination over Composite Key Under Load
export async function hq10KeysetPagination(prisma: PrismaClient, cursorTime: string, cursorId: number, limit = 50) {
  const cursorDate = new Date(cursorTime);
  return await prisma.flight.findMany({
    where: {
      OR: [
        { scheduled_departure: { gt: cursorDate } },
        {
          scheduled_departure: cursorDate,
          flight_id: { gt: cursorId },
        },
      ],
    },
    orderBy: [
      { scheduled_departure: 'asc' },
      { flight_id: 'asc' },
    ],
    take: limit,
  });
}

// HQ11: High-Dimensional Dynamic Faceted Flight Search Engine (10 Optional Predicates)
export async function hq11DynamicFacetedSearch(prisma: PrismaClient, params: FlightSearchParams) {
  const where: Prisma.flightWhereInput = {};

  if (params.origins && params.origins.length > 0) {
    where.departure_airport = { in: params.origins };
  }
  if (params.destinations && params.destinations.length > 0) {
    where.arrival_airport = { in: params.destinations };
  }
  if (params.minDeparture || params.maxDeparture) {
    where.scheduled_departure = {};
    if (params.minDeparture) {
      where.scheduled_departure.gte = params.minDeparture;
    }
    if (params.maxDeparture) {
      where.scheduled_departure.lte = params.maxDeparture;
    }
  }
  if (params.aircraftClass && params.aircraftClass.length > 0) {
    where.aircraft = where.aircraft || {};
    where.aircraft.class = { in: params.aircraftClass };
  }
  if (params.minRange != null) {
    where.aircraft = where.aircraft || {};
    where.aircraft.range = { gte: params.minRange };
  }
  if (params.statuses && params.statuses.length > 0) {
    where.status = { in: params.statuses };
  }
  if (params.cursorTime && params.cursorId != null) {
    where.OR = [
      { scheduled_departure: { gt: params.cursorTime } },
      {
        scheduled_departure: params.cursorTime,
        flight_id: { gt: params.cursorId },
      },
    ];
  }

  return await prisma.flight.findMany({
    where,
    include: {
      aircraft: true,
    },
    orderBy: [
      { scheduled_departure: 'asc' },
      { flight_id: 'asc' },
    ],
    take: params.limit || 100,
  });
}

// HQ12: High-Volume Batch Upsert (2,500 Records with Conflict Resolution)
export async function hq12BatchUpsert(prisma: PrismaClient, updates: Array<{
  flightId: number;
  status: string;
  actualDeparture: Date;
  actualArrival: Date;
  updateTs: Date;
  version: number;
}>) {
  const rows: string[] = [];
  const params: any[] = [];
  let idx = 1;
  for (const u of updates) {
    rows.push(`($${idx}, $${idx + 1}, $${idx + 2}, $${idx + 3}, $${idx + 4}, $${idx + 5})`);
    params.push(u.flightId, u.status, u.actualDeparture, u.actualArrival, u.updateTs, u.version);
    idx += 6;
  }
  const rawSql = `
    INSERT INTO postgres_air.flight_status_update (flight_id, status, actual_departure, actual_arrival, update_ts, version)
    VALUES ${rows.join(', ')}
    ON CONFLICT (flight_id) DO UPDATE SET
      status = EXCLUDED.status,
      actual_departure = EXCLUDED.actual_departure,
      actual_arrival = EXCLUDED.actual_arrival,
      update_ts = EXCLUDED.update_ts,
      version = postgres_air.flight_status_update.version + 1
  `;
  await prisma.$executeRawUnsafe(rawSql, ...params);
  return updates.length;
}

// HQ13: Optimistic Concurrency Bulk Fare & Status Adjustment
export async function hq13OptimisticBulkUpdate(prisma: PrismaClient, minFid: number, maxFid: number, expectedVer: number, newStatus: string) {
  const res = await prisma.flight.updateMany({
    where: {
      flight_id: { gte: minFid, lte: maxFid },
      version: expectedVer,
    },
    data: {
      status: newStatus,
      version: { increment: 1 },
      update_ts: new Date(),
    },
  });
  return res.count;
}

// HQ14: High-Concurrency Seat Allocation Under Contention (C=100)
export async function hq14ReserveSeatConcurrent(prisma: PrismaClient, flightId: number, passengerName: string) {
  return await prisma.$transaction(async (tx) => {
    const selSql = `
      SELECT seat_no, version FROM postgres_air.flight_seat_inventory
      WHERE flight_id = $1 AND status = 'AVAILABLE'
      LIMIT 1 FOR UPDATE
    `;
    const rows: any[] = await tx.$queryRawUnsafe(selSql, flightId);
    if (!rows || rows.length === 0) {
      return 'Sold Out';
    }
    const seat = rows[0];
    const updateSql = `
      UPDATE postgres_air.flight_seat_inventory
      SET status = 'RESERVED', passenger_name = $1, reserved_at = clock_timestamp(), version = version + 1
      WHERE flight_id = $2 AND seat_no = $3 AND version = $4
    `;
    await tx.$executeRawUnsafe(updateSql, passengerName, flightId, seat.seat_no, seat.version);
    return seat.seat_no;
  });
}

// HQ15: Distributed Financial / Points Transfer with Serialization Retry
export async function hq15PointsTransferSerializable(prisma: PrismaClient, fromAcc: number, toAcc: number, points: number) {
  const maxRetries = 5;
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      await prisma.$transaction(async (tx) => {
        await tx.frequent_flyer.update({
          where: { frequent_flyer_id: fromAcc },
          data: { award_points: { decrement: points } },
        });
        await tx.frequent_flyer.update({
          where: { frequent_flyer_id: toAcc },
          data: { award_points: { increment: points } },
        });
      }, {
        isolationLevel: Prisma.TransactionIsolationLevel.Serializable,
      });
      return;
    } catch (err: any) {
      if ((err.code === 'P2034' || err.message?.includes('could not serialize') || err.message?.includes('40001')) && attempt < maxRetries - 1) {
        await new Promise((r) => setTimeout(r, 10 * Math.pow(2, attempt)));
        continue;
      }
      throw err;
    }
  }
}

// HQ16: Multi-Modal Hybrid Vector Similarity + BM25 RRF Search
export async function hq16HybridSearchRRF(prisma: PrismaClient, targetAirport = 'LHR', queryText = 'London Heathrow international hub') {
  const sql = Prisma.sql`
    WITH text_ranking AS (
        SELECT airport_code,
               ROW_NUMBER() OVER (ORDER BY ts_rank_cd(search_tsv, plainto_tsquery('english', ${queryText})) DESC) AS rank_text
        FROM postgres_air.airport
        WHERE search_tsv @@ plainto_tsquery('english', ${queryText})
        LIMIT 25
    ),
    vector_ranking AS (
        SELECT airport_code,
               ROW_NUMBER() OVER (ORDER BY (embedding <=> (SELECT embedding FROM postgres_air.airport WHERE airport_code = ${targetAirport})) ASC) AS rank_vec
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
  return await prisma.$queryRaw(sql);
}
