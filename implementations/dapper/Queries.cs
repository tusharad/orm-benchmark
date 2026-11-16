using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading;
using Dapper;
using Npgsql;
using DapperAirBench.Models;

namespace DapperAirBench;

public static class Queries
{
    // HQ01: Massive Entity Deserialization (10,000 Wide Rows)
    public static List<Flight> Hq01(NpgsqlConnection conn)
    {
        var sql = @"
SELECT flight_id, flight_no, scheduled_departure, scheduled_arrival,
       departure_airport, arrival_airport, status, aircraft_code,
       actual_departure, actual_arrival, update_ts, version
FROM postgres_air.flight
ORDER BY flight_id
LIMIT 10000;";
        return conn.Query<Flight>(sql).AsList();
    }

    // HQ02: Wide Multi-Join Composite Hydration (5,000 Joined Records Across 4 Relations)
    public static List<CompositeBookingRecord> Hq02(NpgsqlConnection conn)
    {
        var sql = @"
SELECT b.booking_id AS BookingId,
       b.booking_ref AS BookingRef,
       b.price AS Price,
       b.email AS Email,
       p.passenger_id AS PassengerId,
       p.first_name AS FirstName,
       p.last_name AS LastName,
       p.age AS Age,
       bl.booking_leg_id AS BookingLegId,
       bl.leg_num AS LegNum,
       bl.is_returning AS IsReturning,
       f.flight_id AS FlightId,
       f.flight_no AS FlightNo,
       f.departure_airport AS DepartureAirport,
       f.arrival_airport AS ArrivalAirport,
       f.scheduled_departure AS ScheduledDeparture,
       f.status AS Status
FROM postgres_air.booking b
JOIN postgres_air.passenger p ON b.booking_id = p.booking_id
JOIN postgres_air.booking_leg bl ON b.booking_id = bl.booking_id
JOIN postgres_air.flight f ON bl.flight_id = f.flight_id
WHERE b.booking_id >= 100000 AND b.booking_id <= 105000
ORDER BY b.booking_id, p.passenger_id, bl.booking_leg_id
LIMIT 5000;";
        return conn.Query<CompositeBookingRecord>(sql).AsList();
    }

    // HQ03: 4-Level Deep Hierarchical Entity Tree Materialization
    public static List<FlightGraphNode> Hq03(NpgsqlConnection conn)
    {
        var sql = @"
SELECT f.flight_id, f.flight_no, f.scheduled_departure, f.scheduled_arrival,
       f.departure_airport, f.arrival_airport, f.status, f.aircraft_code,
       f.actual_departure, f.actual_arrival, f.update_ts, f.version,
       bl.booking_leg_id, bl.booking_id, bl.flight_id, bl.leg_num, bl.is_returning, bl.update_ts,
       b.booking_id, b.booking_ref, b.booking_name, b.account_id, b.email, b.phone, b.update_ts, b.price,
       bp.pass_id, bp.passenger_id, bp.booking_leg_id, bp.seat, bp.boarding_time, bp.update_ts
FROM postgres_air.flight f
JOIN postgres_air.booking_leg bl ON f.flight_id = bl.flight_id
JOIN postgres_air.booking b ON bl.booking_id = b.booking_id
LEFT JOIN postgres_air.boarding_pass bp ON bl.booking_leg_id = bp.booking_leg_id
WHERE f.flight_id >= 2000 AND f.flight_id <= 2025
ORDER BY f.flight_id, bl.booking_leg_id, COALESCE(bp.pass_id, 0);";

        var flightMap = new Dictionary<int, FlightGraphNode>();
        var legMap = new Dictionary<int, BookingLegNode>();

        conn.Query<Flight, BookingLeg, Booking, BoardingPass, object>(
            sql,
            (flight, leg, booking, pass) =>
            {
                if (!flightMap.TryGetValue(flight.FlightId, out var node))
                {
                    node = new FlightGraphNode(flight, new List<BookingLegNode>());
                    flightMap[flight.FlightId] = node;
                }

                if (!legMap.TryGetValue(leg.BookingLegId, out var legNode))
                {
                    legNode = new BookingLegNode(leg, booking, pass);
                    legMap[leg.BookingLegId] = legNode;
                    node.Legs.Add(legNode);
                }

                return null!;
            },
            splitOn: "booking_leg_id,booking_id,pass_id"
        );

        return flightMap.Values.ToList();
    }

    // HQ04: Account Relationship Graph with Optional Sub-Entities
    public static List<object> Hq04(NpgsqlConnection conn)
    {
        var sql = @"
SELECT a.account_id, a.login, a.first_name, a.last_name,
       ff.level AS ff_level, ff.award_points,
       ph.phone_id, ph.phone AS phone_number, ph.phone_type,
       b.booking_id, b.booking_ref, b.price,
       p.passenger_id, p.first_name AS passenger_first_name, p.last_name AS passenger_last_name
FROM postgres_air.account a
LEFT JOIN postgres_air.frequent_flyer ff ON a.frequent_flyer_id = ff.frequent_flyer_id
LEFT JOIN postgres_air.phone ph ON a.account_id = ph.account_id
LEFT JOIN postgres_air.booking b ON a.account_id = b.account_id
LEFT JOIN postgres_air.passenger p ON b.booking_id = p.booking_id
WHERE a.account_id >= 50000 AND a.account_id <= 50200
ORDER BY a.account_id, COALESCE(ph.phone_id, 0), COALESCE(b.booking_id, 0), COALESCE(p.passenger_id, 0)
LIMIT 7000;";
        return conn.Query<object>(sql).AsList();
    }

    // HQ05: Fleet & Route Profitability Analytical Ledger (5-Table Join over 400k+ Rows)
    public static List<RouteProfitability> Hq05(NpgsqlConnection conn)
    {
        var sql = @"
SELECT orig.airport_code AS origin,
       dest.airport_code AS destination,
       ac.model AS aircraft_model,
       count(DISTINCT f.flight_id) AS total_flights,
       count(bl.booking_leg_id) AS total_legs_booked,
       round(sum(b.price), 2) AS total_revenue,
       round(avg(EXTRACT(EPOCH FROM (f.actual_departure - f.scheduled_departure)) / 60), 2) AS avg_delay_minutes,
       round(100.0 * count(CASE WHEN f.actual_departure <= f.scheduled_departure + INTERVAL '15 minutes' THEN 1 END) / count(f.flight_id), 2) AS on_time_pct
FROM postgres_air.flight f
JOIN postgres_air.airport orig ON f.departure_airport = orig.airport_code
JOIN postgres_air.airport dest ON f.arrival_airport = dest.airport_code
JOIN postgres_air.aircraft ac ON f.aircraft_code = ac.code
JOIN postgres_air.booking_leg bl ON f.flight_id = bl.flight_id
JOIN postgres_air.booking b ON bl.booking_id = b.booking_id
WHERE f.scheduled_departure >= '2024-07-01 00:00:00+00' 
  AND f.scheduled_departure < '2024-07-04 00:00:00+00'
GROUP BY orig.airport_code, dest.airport_code, ac.model
HAVING count(DISTINCT f.flight_id) >= 3
ORDER BY total_revenue DESC
LIMIT 50;";
        return conn.Query<RouteProfitability>(sql).AsList();
    }

    // HQ06: Chained Multi-Stage CTEs (Airport Hub Centrality & Network Degree)
    public static List<HubCentrality> Hq06(NpgsqlConnection conn)
    {
        var sql = @"
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
LIMIT 50;";
        return conn.Query<HubCentrality>(sql).AsList();
    }

    // HQ07: Correlated At-Capacity Subquery with Loyalty Tier Cross-Check
    public static List<object> Hq07(NpgsqlConnection conn)
    {
        var sql = @"
SELECT f.flight_id, f.flight_no, f.departure_airport, f.arrival_airport, f.scheduled_departure,
       ac.model AS aircraft_model,
       ac.range AS aircraft_range,
       (SELECT count(*) FROM postgres_air.booking_leg bl WHERE bl.flight_id = f.flight_id) AS seats_booked,
       (
           SELECT count(*)
           FROM postgres_air.booking_leg bl
           JOIN postgres_air.passenger p ON bl.booking_id = p.booking_id
           JOIN postgres_air.account a ON p.account_id = a.account_id
           JOIN postgres_air.frequent_flyer ff ON a.frequent_flyer_id = ff.frequent_flyer_id
           WHERE bl.flight_id = f.flight_id AND ff.level >= 3
       ) AS elite_flyer_count
FROM postgres_air.flight f
JOIN postgres_air.aircraft ac ON f.aircraft_code = ac.code
WHERE f.scheduled_departure >= '2024-07-01 00:00:00+00' AND f.scheduled_departure < '2024-07-03 00:00:00+00'
  AND ac.class >= 2
  AND (SELECT count(*) FROM postgres_air.booking_leg bl WHERE bl.flight_id = f.flight_id) > 40
  AND EXISTS (
      SELECT 1 FROM postgres_air.flight route_f
      WHERE route_f.departure_airport = f.departure_airport
        AND route_f.arrival_airport = f.arrival_airport
        AND route_f.status = 'Canceled'
        AND route_f.scheduled_departure >= '2024-06-01 00:00:00+00'
  )
ORDER BY seats_booked DESC
LIMIT 100;";
        return conn.Query<object>(sql).AsList();
    }

    // HQ08: Recursive Multi-Hop Flight Connection Graph Search (1- to 3-Hop Paths)
    public static List<Itinerary> Hq08(NpgsqlConnection conn)
    {
        var sql = @"
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
LIMIT 25;";
        return conn.Query<Itinerary>(sql).AsList();
    }

    // HQ09: Multi-Window Statistical Delay Dispersion & Cascades
    public static List<WindowDelay> Hq09(NpgsqlConnection conn)
    {
        var sql = @"
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
LIMIT 5000;";
        return conn.Query<WindowDelay>(sql).AsList();
    }

    // HQ10: High-Throughput Keyset (Cursor) Pagination over Composite Key Under Load
    public static List<Flight> Hq10(NpgsqlConnection conn, DateTime? cursorTime = null, int? cursorId = null)
    {
        var cTime = cursorTime ?? new DateTime(2024, 7, 15, 12, 0, 0, DateTimeKind.Utc);
        var cId = cursorId ?? 10500;

        var sql = @"
SELECT flight_id, flight_no, scheduled_departure, scheduled_arrival,
       departure_airport, arrival_airport, status, aircraft_code,
       actual_departure, actual_arrival, update_ts, version
FROM postgres_air.flight
WHERE scheduled_departure > @cursorTime OR (scheduled_departure = @cursorTime AND flight_id > @cursorId)
ORDER BY scheduled_departure, flight_id
LIMIT 50;";

        return conn.Query<Flight>(sql, new { cursorTime = cTime, cursorId = cId }).AsList();
    }

    // HQ11: High-Dimensional Dynamic Faceted Flight Search Engine (10 Optional Predicates)
    public static List<object> Hq11(NpgsqlConnection conn,
        List<string>? depAirports = null,
        List<string>? arrAirports = null,
        DateTime? tStart = null,
        DateTime? tEnd = null,
        List<int>? classes = null,
        decimal? minRange = null,
        List<string>? statuses = null,
        int? hMin = null,
        int? hMax = null,
        DateTime? cursorTime = null,
        int? cursorId = null)
    {
        var deps = depAirports ?? new List<string> { "JFK", "BOS", "EWR" };
        var arrs = arrAirports ?? new List<string> { "LAX", "SFO", "SEA" };
        var t0 = tStart ?? new DateTime(2024, 7, 1, 0, 0, 0, DateTimeKind.Utc);
        var t1 = tEnd ?? new DateTime(2024, 7, 15, 23, 59, 59, DateTimeKind.Utc);
        var cls = classes ?? new List<int> { 1, 2, 3 };
        var rng = minRange ?? 2000m;
        var st = statuses ?? new List<string> { "On time", "Delayed" };
        var h0 = hMin ?? 6;
        var h1 = hMax ?? 21;
        var cTime = cursorTime ?? new DateTime(2024, 7, 1, 6, 0, 0, DateTimeKind.Utc);
        var cId = cursorId ?? 500;

        var sql = @"
SELECT f.flight_id, f.flight_no, f.departure_airport, f.arrival_airport,
       f.scheduled_departure, f.scheduled_arrival, f.status,
       ac.model AS aircraft_model,
       ac.range AS aircraft_range,
       ac.class AS aircraft_class
FROM postgres_air.flight f
JOIN postgres_air.aircraft ac ON f.aircraft_code = ac.code
WHERE f.departure_airport = ANY(@deps)
  AND f.arrival_airport = ANY(@arrs)
  AND f.scheduled_departure >= @t0
  AND f.scheduled_departure <= @t1
  AND ac.class = ANY(@cls)
  AND ac.range >= @rng
  AND f.status = ANY(@st)
  AND EXTRACT(HOUR FROM f.scheduled_departure) >= @h0
  AND EXTRACT(HOUR FROM f.scheduled_departure) <= @h1
  AND (f.scheduled_departure > @cTime OR (f.scheduled_departure = @cTime AND f.flight_id > @cId))
ORDER BY f.scheduled_departure, f.flight_id
LIMIT 100;";

        return conn.Query<object>(sql, new {
            deps, arrs, t0, t1, cls, rng, st, h0, h1, cTime, cId
        }).AsList();
    }

    // HQ12: High-Volume Batch Upsert (2,500 Records with Conflict Resolution)
    public static int Hq12(NpgsqlConnection conn)
    {
        var sb = new StringBuilder();
        sb.Append(@"
INSERT INTO postgres_air.flight_status_update (flight_id, status, actual_departure, actual_arrival, update_ts, version)
VALUES ");
        var now = DateTime.UtcNow;
        for (int i = 1; i <= 2500; i++)
        {
            if (i > 1) sb.Append(',');
            sb.Append($"({i}, 'Departed', '2024-07-01 08:05:00+00', '2024-07-01 11:15:00+00', '{now:O}', 1)");
        }
        sb.Append(@"
ON CONFLICT (flight_id) DO UPDATE SET
    status = EXCLUDED.status,
    actual_departure = EXCLUDED.actual_departure,
    actual_arrival = EXCLUDED.actual_arrival,
    update_ts = EXCLUDED.update_ts,
    version = postgres_air.flight_status_update.version + 1;");

        return conn.Execute(sb.ToString());
    }

    // HQ13: Optimistic Concurrency Bulk Fare & Status Adjustment
    public static int Hq13(NpgsqlConnection conn)
    {
        var updateSql = @"
UPDATE postgres_air.flight
SET status = 'Boarding', version = version + 1, update_ts = NOW()
WHERE flight_id >= 1000 AND flight_id <= 1050 AND version = 1;";

        var resetSql = @"
UPDATE postgres_air.flight
SET status = 'Departed', version = 1
WHERE flight_id >= 1000 AND flight_id <= 1050;";

        var affected = conn.Execute(updateSql);
        conn.Execute(resetSql);
        return affected;
    }

    // HQ14: High-Concurrency Seat Allocation Under Contention (C=100)
    public static string? Hq14(NpgsqlConnection conn, int flightId = 101)
    {
        using var tx = conn.BeginTransaction();
        var seat = conn.QueryFirstOrDefault<FlightSeatInventory>(
            "SELECT flight_id, seat_no, version FROM postgres_air.flight_seat_inventory WHERE flight_id = @flightId AND status = 'AVAILABLE' LIMIT 1 FOR UPDATE;",
            new { flightId },
            transaction: tx
        );

        if (seat != null)
        {
            conn.Execute(
                @"UPDATE postgres_air.flight_seat_inventory
                  SET status = 'RESERVED', passenger_name = 'Test Concurrent Flyer', reserved_at = NOW(), version = version + 1
                  WHERE flight_id = @flightId AND seat_no = @seatNo AND version = @version;",
                new { flightId = seat.FlightId, seatNo = seat.SeatNo, version = seat.Version },
                transaction: tx
            );
            tx.Commit();
            return seat.SeatNo;
        }

        tx.Commit();
        return null;
    }

    // HQ15: Distributed Financial / Points Transfer with 40001 Retry
    public static bool Hq15(NpgsqlConnection conn, int fromId = 1001, int toId = 1002, int points = 500, int maxRetries = 5)
    {
        for (int attempt = 1; attempt <= maxRetries; attempt++)
        {
            try
            {
                using var tx = conn.BeginTransaction(IsolationLevel.Serializable);
                conn.Execute(
                    "UPDATE postgres_air.frequent_flyer SET award_points = award_points - @points WHERE frequent_flyer_id = @fromId;",
                    new { points, fromId },
                    transaction: tx
                );
                conn.Execute(
                    "UPDATE postgres_air.frequent_flyer SET award_points = award_points + @points WHERE frequent_flyer_id = @toId;",
                    new { points, toId },
                    transaction: tx
                );
                tx.Commit();

                // Revert
                using var revertTx = conn.BeginTransaction();
                conn.Execute(
                    "UPDATE postgres_air.frequent_flyer SET award_points = award_points + @points WHERE frequent_flyer_id = @fromId;",
                    new { points, fromId },
                    transaction: revertTx
                );
                conn.Execute(
                    "UPDATE postgres_air.frequent_flyer SET award_points = award_points - @points WHERE frequent_flyer_id = @toId;",
                    new { points, toId },
                    transaction: revertTx
                );
                revertTx.Commit();
                return true;
            }
            catch (PostgresException ex) when (ex.SqlState == "40001" && attempt < maxRetries)
            {
                Thread.Sleep(attempt * 10);
            }
        }
        return false;
    }

    // HQ16: Multi-Modal Hybrid Vector Similarity + BM25 RRF Search
    public static List<HybridAirport> Hq16(NpgsqlConnection conn)
    {
        var sql = @"
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
LIMIT 25;";
        return conn.Query<HybridAirport>(sql).AsList();
    }
}
