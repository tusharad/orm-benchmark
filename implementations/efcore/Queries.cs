using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using EFCoreAirBench.Models;

namespace EFCoreAirBench;

public record CompositeBookingRecord(
    long BookingId, string BookingRef, decimal? Price, string Email,
    int PassengerId, string FirstName, string LastName, int? Age,
    int BookingLegId, int? LegNum, bool? IsReturning,
    int FlightId, string FlightNo, string DepartureAirport, string ArrivalAirport,
    DateTime ScheduledDeparture, string Status
);

public record FlightGraphNode(Flight Flight, List<BookingLegNode> Legs);
public record BookingLegNode(BookingLeg Leg, Booking Booking, BoardingPass? BoardingPass);

public record RouteProfitability(
    string origin, string destination, string aircraft_model,
    long total_flights, long total_legs_booked, decimal total_revenue,
    decimal avg_delay_minutes, decimal on_time_pct
);

public record HubCentrality(
    string airport_code, string airport_name, string city,
    long total_departures, long total_arrivals, long unique_destinations,
    long fleet_diversity, decimal avg_dep_delay, decimal avg_arr_delay,
    decimal hub_centrality_score
);

public record Itinerary(
    int hops, string route, DateTime journey_start, DateTime journey_end,
    decimal total_elapsed_minutes, decimal total_flight_minutes
);

public record WindowDelay(
    int flight_id, string flight_no, string arrival_airport, DateTime scheduled_departure,
    decimal delay_minutes, decimal rolling_avg_delay_5, decimal? delay_diff_prev,
    decimal rolling_stddev_10, long severity_rank
);

public record HybridAirport(
    string airport_code, string airport_name, string city,
    long active_flights_count, decimal rrf_score
);

public static class Queries
{
    // HQ01: Massive Entity Deserialization (10,000 Wide Rows)
    public static List<Flight> Hq01(AirDbContext db)
    {
        return db.Flights.AsNoTracking().OrderBy(f => f.FlightId).Take(10000).ToList();
    }

    // HQ02: Wide Multi-Join Composite Hydration (5,000 Joined Records Across 4 Relations)
    public static List<CompositeBookingRecord> Hq02(AirDbContext db)
    {
        return (
            from b in db.Bookings.AsNoTracking()
            join p in db.Passengers.AsNoTracking() on b.BookingId equals p.BookingId
            join bl in db.BookingLegs.AsNoTracking() on b.BookingId equals bl.BookingId
            join f in db.Flights.AsNoTracking() on bl.FlightId equals f.FlightId
            where b.BookingId >= 100000 && b.BookingId <= 105000
            orderby b.BookingId, p.PassengerId, bl.BookingLegId
            select new CompositeBookingRecord(
                b.BookingId, b.BookingRef, b.Price, b.Email,
                p.PassengerId, p.FirstName, p.LastName, p.Age,
                bl.BookingLegId, bl.LegNum, bl.IsReturning,
                f.FlightId, f.FlightNo, f.DepartureAirport, f.ArrivalAirport,
                f.ScheduledDeparture, f.Status
            )
        ).Take(5000).ToList();
    }

    // HQ03: 4-Level Deep Hierarchical Entity Tree Materialization
    public static List<FlightGraphNode> Hq03(AirDbContext db)
    {
        var flat = (
            from f in db.Flights.AsNoTracking()
            join bl in db.BookingLegs.AsNoTracking() on f.FlightId equals bl.FlightId
            join b in db.Bookings.AsNoTracking() on bl.BookingId equals b.BookingId
            join bp in db.BoardingPasses.AsNoTracking() on (long)bl.BookingLegId equals bp.BookingLegId into bpGroup
            from bp in bpGroup.DefaultIfEmpty()
            where f.FlightId >= 2000 && f.FlightId <= 2025
            orderby f.FlightId, bl.BookingLegId, bp != null ? bp.PassId : 0
            select new { Flight = f, Leg = bl, Booking = b, BoardingPass = bp }
        ).ToList();

        return flat
            .GroupBy(x => x.Flight.FlightId)
            .Select(g => new FlightGraphNode(
                g.First().Flight,
                g.GroupBy(x => x.Leg.BookingLegId)
                 .Select(lg => new BookingLegNode(lg.First().Leg, lg.First().Booking, lg.First().BoardingPass))
                 .ToList()
            ))
            .ToList();
    }

    // HQ04: Account Relationship Graph with Optional Sub-Entities
    public static List<object> Hq04(AirDbContext db)
    {
        return (
            from a in db.Accounts.AsNoTracking()
            join ff in db.FrequentFlyers.AsNoTracking() on a.FrequentFlyerId equals ff.FrequentFlyerId into ffGroup
            from ff in ffGroup.DefaultIfEmpty()
            join ph in db.Phones.AsNoTracking() on a.AccountId equals ph.AccountId into phGroup
            from ph in phGroup.DefaultIfEmpty()
            join b in db.Bookings.AsNoTracking() on a.AccountId equals b.AccountId into bGroup
            from b in bGroup.DefaultIfEmpty()
            join p in db.Passengers.AsNoTracking() on b != null ? b.BookingId : 0 equals p.BookingId into pGroup
            from p in pGroup.DefaultIfEmpty()
            where a.AccountId >= 50000 && a.AccountId <= 50200
            orderby a.AccountId, ph != null ? ph.PhoneId : 0, b != null ? b.BookingId : 0, p != null ? p.PassengerId : 0
            select new {
                a.AccountId, a.Login, a.FirstName, a.LastName,
                FfLevel = ff != null ? (int?)ff.Level : null,
                AwardPoints = ff != null ? (int?)ff.AwardPoints : null,
                PhoneId = ph != null ? (int?)ph.PhoneId : null,
                PhoneNumber = ph != null ? ph.PhoneNumber : null,
                PhoneType = ph != null ? ph.PhoneType : null,
                BookingId = b != null ? (long?)b.BookingId : null,
                BookingRef = b != null ? b.BookingRef : null,
                Price = b != null ? b.Price : null,
                PassengerId = p != null ? (int?)p.PassengerId : null,
                PassengerFirstName = p != null ? p.FirstName : null,
                PassengerLastName = p != null ? p.LastName : null
            }
        ).Take(7000).ToList<object>();
    }

    // HQ05: Fleet & Route Profitability Analytical Ledger (5-Table Join over 400k+ Rows)
    public static List<RouteProfitability> Hq05(AirDbContext db)
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
        return db.Database.SqlQueryRaw<RouteProfitability>(sql).ToList();
    }

    // HQ06: Chained Multi-Stage CTEs (Airport Hub Centrality & Network Degree)
    public static List<HubCentrality> Hq06(AirDbContext db)
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
        return db.Database.SqlQueryRaw<HubCentrality>(sql).ToList();
    }

    // HQ07: Correlated At-Capacity Subquery with Loyalty Tier Cross-Check
    public static List<object> Hq07(AirDbContext db)
    {
        var tStart = new DateTime(2024, 7, 1, 0, 0, 0, DateTimeKind.Utc);
        var tEnd = new DateTime(2024, 7, 3, 0, 0, 0, DateTimeKind.Utc);
        var tCancel = new DateTime(2024, 6, 1, 0, 0, 0, DateTimeKind.Utc);

        return (
            from f in db.Flights.AsNoTracking()
            join ac in db.Aircrafts.AsNoTracking() on f.AircraftCode equals ac.Code
            where f.ScheduledDeparture >= tStart && f.ScheduledDeparture < tEnd
               && ac.Class >= 2
               && db.BookingLegs.Count(bl => bl.FlightId == f.FlightId) > 40
               && db.Flights.Any(routeF => routeF.DepartureAirport == f.DepartureAirport
                                        && routeF.ArrivalAirport == f.ArrivalAirport
                                        && routeF.Status == "Canceled"
                                        && routeF.ScheduledDeparture >= tCancel)
            orderby db.BookingLegs.Count(bl => bl.FlightId == f.FlightId) descending
            select new {
                f.FlightId, f.FlightNo, f.DepartureAirport, f.ArrivalAirport, f.ScheduledDeparture,
                AircraftModel = ac.Model,
                AircraftRange = ac.Range,
                SeatsBooked = db.BookingLegs.Count(bl => bl.FlightId == f.FlightId),
                EliteFlyerCount = (
                    from bl in db.BookingLegs
                    join p in db.Passengers on bl.BookingId equals p.BookingId
                    join a in db.Accounts on p.AccountId equals a.AccountId
                    join ff in db.FrequentFlyers on a.FrequentFlyerId equals ff.FrequentFlyerId
                    where bl.FlightId == f.FlightId && ff.Level >= 3
                    select bl.BookingLegId
                ).Count()
            }
        ).Take(100).ToList<object>();
    }

    // HQ08: Recursive Multi-Hop Flight Connection Graph Search (1- to 3-Hop Paths)
    public static List<Itinerary> Hq08(AirDbContext db)
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
        return db.Database.SqlQueryRaw<Itinerary>(sql).ToList();
    }

    // HQ09: Multi-Window Statistical Delay Dispersion & Cascades
    public static List<WindowDelay> Hq09(AirDbContext db)
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
        return db.Database.SqlQueryRaw<WindowDelay>(sql).ToList();
    }

    // HQ10: High-Throughput Keyset (Cursor) Pagination over Composite Key Under Load
    public static List<Flight> Hq10(AirDbContext db, DateTime? cursorTime = null, int? cursorId = null)
    {
        var cTime = cursorTime ?? new DateTime(2024, 7, 15, 12, 0, 0, DateTimeKind.Utc);
        var cId = cursorId ?? 10500;

        return db.Flights.AsNoTracking()
            .Where(f => f.ScheduledDeparture > cTime || (f.ScheduledDeparture == cTime && f.FlightId > cId))
            .OrderBy(f => f.ScheduledDeparture)
            .ThenBy(f => f.FlightId)
            .Take(50)
            .ToList();
    }

    // HQ11: High-Dimensional Dynamic Faceted Flight Search Engine (10 Optional Predicates)
    public static List<object> Hq11(AirDbContext db,
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

        IQueryable<Flight> q = db.Flights.AsNoTracking().Include(f => f.Aircraft);

        if (deps.Count > 0) q = q.Where(f => deps.Contains(f.DepartureAirport));
        if (arrs.Count > 0) q = q.Where(f => arrs.Contains(f.ArrivalAirport));
        q = q.Where(f => f.ScheduledDeparture >= t0);
        q = q.Where(f => f.ScheduledDeparture <= t1);
        if (cls.Count > 0) q = q.Where(f => cls.Contains(f.Aircraft!.Class));
        q = q.Where(f => f.Aircraft!.Range >= rng);
        if (st.Count > 0) q = q.Where(f => st.Contains(f.Status));
        q = q.Where(f => f.ScheduledDeparture.Hour >= h0 && f.ScheduledDeparture.Hour <= h1);
        q = q.Where(f => f.ScheduledDeparture > cTime || (f.ScheduledDeparture == cTime && f.FlightId > cId));

        return q.OrderBy(f => f.ScheduledDeparture)
                .ThenBy(f => f.FlightId)
                .Take(100)
                .Select(f => new {
                    f.FlightId, f.FlightNo, f.DepartureAirport, f.ArrivalAirport,
                    f.ScheduledDeparture, f.ScheduledArrival, f.Status,
                    AircraftModel = f.Aircraft != null ? f.Aircraft.Model : null,
                    AircraftRange = f.Aircraft != null ? (decimal?)f.Aircraft.Range : null,
                    AircraftClass = f.Aircraft != null ? (int?)f.Aircraft.Class : null
                })
                .ToList<object>();
    }

    // HQ12: High-Volume Batch Upsert (2,500 Records with Conflict Resolution)
    public static int Hq12(AirDbContext db)
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

        return db.Database.ExecuteSqlRaw(sb.ToString());
    }

    // HQ13: Optimistic Concurrency Bulk Fare & Status Adjustment
    public static int Hq13(AirDbContext db)
    {
        var updated = db.Flights
            .Where(f => f.FlightId >= 1000 && f.FlightId <= 1050 && f.Version == 1)
            .ExecuteUpdate(s => s
                .SetProperty(f => f.Status, "Boarding")
                .SetProperty(f => f.Version, f => f.Version + 1)
                .SetProperty(f => f.UpdateTs, DateTime.UtcNow)
            );

        // Reset version for future benchmark iterations
        db.Flights.Where(f => f.FlightId >= 1000 && f.FlightId <= 1050)
                  .ExecuteUpdate(s => s.SetProperty(f => f.Status, "Departed").SetProperty(f => f.Version, 1));

        return updated;
    }

    // HQ14: High-Concurrency Seat Allocation Under Contention (C=100)
    public static string? Hq14(AirDbContext db, int flightId = 101)
    {
        using var tx = db.Database.BeginTransaction();
        var seat = db.FlightSeatInventories
            .FromSqlInterpolated($"SELECT flight_id, seat_no, passenger_name, account_id, reserved_at, status, version FROM postgres_air.flight_seat_inventory WHERE flight_id = {flightId} AND status = 'AVAILABLE' LIMIT 1 FOR UPDATE")
            .FirstOrDefault();

        if (seat != null)
        {
            db.FlightSeatInventories
                .Where(s => s.FlightId == flightId && s.SeatNo == seat.SeatNo && s.Version == seat.Version)
                .ExecuteUpdate(u => u
                    .SetProperty(s => s.Status, "RESERVED")
                    .SetProperty(s => s.PassengerName, "Test Concurrent Flyer")
                    .SetProperty(s => s.ReservedAt, DateTime.UtcNow)
                    .SetProperty(s => s.Version, s => s.Version + 1)
                );
            tx.Commit();
            return seat.SeatNo;
        }
        tx.Commit();
        return null;
    }

    // HQ15: Distributed Financial / Points Transfer with 40001 Retry
    public static bool Hq15(AirDbContext db, int fromId = 1001, int toId = 1002, int points = 500, int maxRetries = 5)
    {
        for (int attempt = 1; attempt <= maxRetries; attempt++)
        {
            try
            {
                using var tx = db.Database.BeginTransaction(System.Data.IsolationLevel.Serializable);
                db.FrequentFlyers.Where(ff => ff.FrequentFlyerId == fromId).ExecuteUpdate(u => u.SetProperty(ff => ff.AwardPoints, ff => ff.AwardPoints - points));
                db.FrequentFlyers.Where(ff => ff.FrequentFlyerId == toId).ExecuteUpdate(u => u.SetProperty(ff => ff.AwardPoints, ff => ff.AwardPoints + points));
                tx.Commit();

                // Revert
                db.FrequentFlyers.Where(ff => ff.FrequentFlyerId == fromId).ExecuteUpdate(u => u.SetProperty(ff => ff.AwardPoints, ff => ff.AwardPoints + points));
                db.FrequentFlyers.Where(ff => ff.FrequentFlyerId == toId).ExecuteUpdate(u => u.SetProperty(ff => ff.AwardPoints, ff => ff.AwardPoints - points));
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
    public static List<HybridAirport> Hq16(AirDbContext db)
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
        return db.Database.SqlQueryRaw<HybridAirport>(sql).ToList();
    }
}
