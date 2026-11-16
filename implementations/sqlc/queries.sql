-- name: HQ01_MassiveDeserialization :many
SELECT flight_id, flight_no, scheduled_departure, scheduled_arrival,
       departure_airport, arrival_airport, status, aircraft_code,
       actual_departure, actual_arrival, update_ts, version
FROM postgres_air.flight
ORDER BY flight_id
LIMIT 10000;

-- name: HQ02_WideMultiJoin :many
SELECT b.booking_id, b.booking_ref, b.price, b.email,
       p.passenger_id, p.first_name, p.last_name, p.age,
       bl.booking_leg_id, bl.leg_num, bl.is_returning,
       f.flight_id, f.flight_no, f.departure_airport, f.arrival_airport, 
       f.scheduled_departure, f.status
FROM postgres_air.booking b
JOIN postgres_air.passenger p ON b.booking_id = p.booking_id
JOIN postgres_air.booking_leg bl ON b.booking_id = bl.booking_id
JOIN postgres_air.flight f ON bl.flight_id = f.flight_id
WHERE b.booking_id BETWEEN 100000 AND 105000
ORDER BY b.booking_id, p.passenger_id, bl.booking_leg_id
LIMIT 5000;

-- name: HQ03_DeepHierarchicalGraph :many
SELECT f.flight_id, f.flight_no, f.departure_airport, f.arrival_airport, f.scheduled_departure,
       bl.booking_leg_id, bl.leg_num,
       b.booking_id, b.booking_ref, b.price,
       bp.pass_id, bp.seat, bp.boarding_time
FROM postgres_air.flight f
JOIN postgres_air.booking_leg bl ON f.flight_id = bl.flight_id
JOIN postgres_air.booking b ON bl.booking_id = b.booking_id
LEFT JOIN postgres_air.boarding_pass bp ON (bp.booking_leg_id = bl.booking_leg_id)
WHERE f.flight_id BETWEEN 2000 AND 2025
ORDER BY f.flight_id, bl.booking_leg_id, bp.pass_id;

-- name: HQ04_AccountRelationshipGraph :many
SELECT a.account_id, a.login, a.first_name, a.last_name,
       ff.frequent_flyer_id, ff.level AS ff_level, ff.award_points,
       ph.phone_id, ph.phone, ph.phone_type,
       b.booking_id, b.booking_ref, b.price AS booking_price,
       p.passenger_id, p.first_name AS passenger_first_name, p.last_name AS passenger_last_name
FROM postgres_air.account a
LEFT JOIN postgres_air.frequent_flyer ff ON a.frequent_flyer_id = ff.frequent_flyer_id
LEFT JOIN postgres_air.phone ph ON a.account_id = ph.account_id
LEFT JOIN postgres_air.booking b ON a.account_id = b.account_id
LEFT JOIN postgres_air.passenger p ON b.booking_id = p.booking_id
WHERE a.account_id BETWEEN 50000 AND 50200
ORDER BY a.account_id, ph.phone_id, b.booking_id, p.passenger_id;

-- name: HQ05_RouteFinancialLedger :many
SELECT orig.airport_code AS origin,
       dest.airport_code AS destination,
       ac.model AS aircraft_model,
       count(DISTINCT f.flight_id)::bigint AS total_flights,
       count(bl.booking_leg_id)::bigint AS total_legs_booked,
       round(coalesce(sum(b.price), 0.0), 2)::numeric AS total_revenue,
       round(coalesce(avg(EXTRACT(EPOCH FROM (f.actual_departure - f.scheduled_departure)) / 60), 0.0)::numeric, 2)::numeric AS avg_delay_minutes,
       round((100.0 * count(CASE WHEN f.actual_departure <= f.scheduled_departure + INTERVAL '15 minutes' THEN 1 END) / count(f.flight_id))::numeric, 2)::numeric AS on_time_pct
FROM postgres_air.flight f
JOIN postgres_air.airport orig ON f.departure_airport = orig.airport_code
JOIN postgres_air.airport dest ON f.arrival_airport = dest.airport_code
JOIN postgres_air.aircraft ac ON f.aircraft_code = ac.code
JOIN postgres_air.booking_leg bl ON f.flight_id = bl.flight_id
JOIN postgres_air.booking b ON bl.booking_id = b.booking_id
WHERE f.scheduled_departure >= '2024-07-01 00:00:00+00'::timestamptz 
  AND f.scheduled_departure < '2024-07-04 00:00:00+00'::timestamptz
GROUP BY orig.airport_code, dest.airport_code, ac.model
HAVING count(DISTINCT f.flight_id) >= 3
ORDER BY total_revenue DESC
LIMIT 50;

-- name: HQ06_HubCentralityDegree :many
WITH flight_volumes AS (
    SELECT departure_airport AS airport_code,
           count(*)::bigint AS departures_count,
           round(avg(EXTRACT(EPOCH FROM (actual_departure - scheduled_departure)) / 60)::numeric, 2)::numeric AS avg_dep_delay
    FROM postgres_air.flight
    WHERE scheduled_departure >= '2024-06-01 00:00:00+00'::timestamptz AND scheduled_departure < '2024-07-01 00:00:00+00'::timestamptz
      AND actual_departure IS NOT NULL
    GROUP BY departure_airport
),
arrival_volumes AS (
    SELECT arrival_airport AS airport_code,
           count(*)::bigint AS arrivals_count,
           round(avg(EXTRACT(EPOCH FROM (actual_arrival - scheduled_arrival)) / 60)::numeric, 2)::numeric AS avg_arr_delay
    FROM postgres_air.flight
    WHERE scheduled_arrival >= '2024-06-01 00:00:00+00'::timestamptz AND scheduled_arrival < '2024-07-01 00:00:00+00'::timestamptz
      AND actual_arrival IS NOT NULL
    GROUP BY arrival_airport
),
route_connectivity AS (
    SELECT departure_airport AS airport_code,
           count(DISTINCT arrival_airport)::bigint AS unique_destinations,
           count(DISTINCT aircraft_code)::bigint AS fleet_diversity
    FROM postgres_air.flight
    WHERE scheduled_departure >= '2024-06-01 00:00:00+00'::timestamptz AND scheduled_departure < '2024-07-01 00:00:00+00'::timestamptz
    GROUP BY departure_airport
)
SELECT a.airport_code,
       a.airport_name,
       a.city,
       coalesce(fv.departures_count, 0)::bigint AS total_departures,
       coalesce(av.arrivals_count, 0)::bigint AS total_arrivals,
       coalesce(rc.unique_destinations, 0)::bigint AS unique_destinations,
       coalesce(rc.fleet_diversity, 0)::bigint AS fleet_diversity,
       coalesce(fv.avg_dep_delay, 0)::numeric AS avg_dep_delay,
       coalesce(av.avg_arr_delay, 0)::numeric AS avg_arr_delay,
       round(
           ((coalesce(fv.departures_count, 0) + coalesce(av.arrivals_count, 0)) * 
           (1.0 + coalesce(rc.unique_destinations, 0) / 100.0) / 
           (1.0 + greatest(coalesce(fv.avg_dep_delay, 0), 0) / 10.0))::numeric, 
           2
       )::numeric AS hub_centrality_score
FROM postgres_air.airport a
JOIN flight_volumes fv ON a.airport_code = fv.airport_code
JOIN arrival_volumes av ON a.airport_code = av.airport_code
JOIN route_connectivity rc ON a.airport_code = rc.airport_code
ORDER BY hub_centrality_score DESC
LIMIT 50;

-- name: HQ07_CorrelatedAtCapacity :many
SELECT f.flight_id,
       f.flight_no,
       f.departure_airport,
       f.arrival_airport,
       f.scheduled_departure,
       ac.model AS aircraft_model,
       ac.range AS aircraft_range,
       (SELECT count(*)::bigint 
        FROM postgres_air.booking_leg bl 
        WHERE bl.flight_id = f.flight_id) AS seats_booked,
       (SELECT count(*)::bigint
        FROM postgres_air.booking_leg bl
        JOIN postgres_air.passenger p ON bl.booking_id = p.booking_id
        JOIN postgres_air.account a ON p.account_id = a.account_id
        JOIN postgres_air.frequent_flyer ff ON a.frequent_flyer_id = ff.frequent_flyer_id
        WHERE bl.flight_id = f.flight_id AND ff.level >= 3) AS elite_flyer_count
FROM postgres_air.flight f
JOIN postgres_air.aircraft ac ON f.aircraft_code = ac.code
WHERE f.scheduled_departure >= '2024-07-01 00:00:00+00'::timestamptz
  AND f.scheduled_departure < '2024-07-03 00:00:00+00'::timestamptz
  AND ac.class >= 2
  AND (
      SELECT count(*) 
      FROM postgres_air.booking_leg bl 
      WHERE bl.flight_id = f.flight_id
  ) > 40
  AND EXISTS (
      SELECT 1 
      FROM postgres_air.flight route_f 
      WHERE route_f.departure_airport = f.departure_airport 
        AND route_f.arrival_airport = f.arrival_airport 
        AND route_f.status = 'Canceled'
        AND route_f.scheduled_departure >= '2024-06-01 00:00:00+00'::timestamptz
  )
ORDER BY seats_booked DESC
LIMIT 100;

-- name: HQ08_RecursiveFlightPaths :many
WITH RECURSIVE flight_paths AS (
    SELECT f.flight_id,
           f.departure_airport::text AS departure_airport,
           f.arrival_airport::text AS arrival_airport,
           f.scheduled_departure,
           f.scheduled_arrival,
           1::int AS hops,
           ARRAY[f.departure_airport::text, f.arrival_airport::text] AS route_airports,
           ARRAY[f.flight_id] AS route_flights,
           f.scheduled_departure AS journey_start,
           f.scheduled_arrival AS journey_end,
           (EXTRACT(EPOCH FROM (f.scheduled_arrival - f.scheduled_departure)) / 60)::numeric(10,2) AS total_flight_minutes
    FROM postgres_air.flight f
    WHERE f.departure_airport = 'JFK'
      AND f.scheduled_departure >= '2024-07-05 00:00:00+00'::timestamptz
      AND f.scheduled_departure < '2024-07-06 00:00:00+00'::timestamptz

    UNION ALL

    SELECT next_f.flight_id,
           fp.departure_airport,
           next_f.arrival_airport::text,
           next_f.scheduled_departure,
           next_f.scheduled_arrival,
           (fp.hops + 1)::int,
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
       array_to_string(route_airports, ' -> ')::text AS route,
       journey_start,
       journey_end,
       (EXTRACT(EPOCH FROM (journey_end - journey_start)) / 60)::numeric(10,2) AS total_elapsed_minutes,
       total_flight_minutes
FROM flight_paths
WHERE arrival_airport = 'ORD'
ORDER BY hops ASC, total_elapsed_minutes ASC
LIMIT 25;

-- name: HQ09_WindowStatisticalDispersion :many
WITH flight_delays AS (
    SELECT flight_id,
           flight_no,
           departure_airport,
           arrival_airport,
           scheduled_departure,
           actual_departure,
           round((EXTRACT(EPOCH FROM (actual_departure - scheduled_departure)) / 60)::numeric, 2)::numeric AS delay_minutes
    FROM postgres_air.flight
    WHERE departure_airport = 'ORD'
      AND actual_departure IS NOT NULL
      AND scheduled_departure >= '2024-06-01 00:00:00+00'::timestamptz
      AND scheduled_departure < '2024-07-01 00:00:00+00'::timestamptz
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
       )::numeric, 2)::numeric AS rolling_avg_delay_5,
       (delay_minutes - lag(delay_minutes, 1) OVER (
           PARTITION BY departure_airport, arrival_airport 
           ORDER BY scheduled_departure
       ))::numeric AS delay_diff_prev,
       round(coalesce(stddev_samp(delay_minutes) OVER (
           PARTITION BY departure_airport, arrival_airport 
           ORDER BY scheduled_departure 
           ROWS BETWEEN 9 PRECEDING AND CURRENT ROW
       ), 0)::numeric, 2)::numeric AS rolling_stddev_10,
       dense_rank() OVER (
           PARTITION BY departure_airport, arrival_airport 
           ORDER BY delay_minutes DESC
       )::bigint AS severity_rank
FROM flight_delays
ORDER BY departure_airport, arrival_airport, scheduled_departure
LIMIT 5000;

-- name: HQ10_KeysetPagination :many
SELECT flight_id, flight_no, departure_airport, arrival_airport, scheduled_departure, status
FROM postgres_air.flight
WHERE (scheduled_departure, flight_id) > ($1::timestamptz, $2::int)
ORDER BY scheduled_departure ASC, flight_id ASC
LIMIT $3::int;

-- name: HQ11_DynamicFacetedSearch :many
SELECT f.flight_id,
       f.flight_no,
       f.departure_airport,
       f.arrival_airport,
       f.scheduled_departure,
       f.scheduled_arrival,
       f.status,
       ac.model AS aircraft_model,
       ac.range AS aircraft_range,
       ac.class AS aircraft_class
FROM postgres_air.flight f
JOIN postgres_air.aircraft ac ON f.aircraft_code = ac.code
WHERE f.departure_airport = ANY($1::character(3)[])
  AND f.arrival_airport = ANY($2::character(3)[])
  AND f.scheduled_departure >= $3::timestamptz
  AND f.scheduled_departure <= $4::timestamptz
  AND ac.class = ANY($5::int[])
  AND f.status = ANY($6::text[])
ORDER BY f.scheduled_departure ASC, f.flight_id ASC
LIMIT 100;

-- name: HQ12_BatchUpsert :execrows
INSERT INTO postgres_air.flight_status_update (flight_id, status, actual_departure, actual_arrival, update_ts, version)
VALUES ($1, $2, $3, $4, $5, $6)
ON CONFLICT (flight_id) DO UPDATE SET
    status = EXCLUDED.status,
    actual_departure = EXCLUDED.actual_departure,
    actual_arrival = EXCLUDED.actual_arrival,
    update_ts = EXCLUDED.update_ts,
    version = postgres_air.flight_status_update.version + 1;

-- name: HQ13_OptimisticConcurrency :many
UPDATE postgres_air.flight
SET status = 'Boarding',
    version = version + 1,
    update_ts = clock_timestamp()
WHERE flight_id BETWEEN $1::int AND $2::int
  AND version = $3::int
RETURNING flight_id, version;

-- name: HQ14_ReserveSeatSelect :one
SELECT flight_id, seat_no, version
FROM postgres_air.flight_seat_inventory
WHERE flight_id = $1::int AND status = 'AVAILABLE'
LIMIT 1
FOR UPDATE;

-- name: HQ14_ReserveSeatUpdate :exec
UPDATE postgres_air.flight_seat_inventory
SET status = 'RESERVED',
    passenger_name = $1::text,
    reserved_at = clock_timestamp(),
    version = version + 1
WHERE flight_id = $2::int AND seat_no = $3::text AND version = $4::int;

-- name: HQ15_DeductPoints :exec
UPDATE postgres_air.frequent_flyer 
SET award_points = award_points - $1::int 
WHERE frequent_flyer_id = $2::int;

-- name: HQ15_AddPoints :exec
UPDATE postgres_air.frequent_flyer 
SET award_points = award_points + $1::int 
WHERE frequent_flyer_id = $2::int;

-- name: HQ16_HybridSearch :many
WITH text_ranking AS (
    SELECT airport_code, 
           ROW_NUMBER() OVER (ORDER BY ts_rank_cd(to_tsvector('english', description), plainto_tsquery('english', 'London Heathrow international hub')) DESC) AS rank_text
    FROM postgres_air.airport
    WHERE to_tsvector('english', description) @@ plainto_tsquery('english', 'London Heathrow international hub')
    LIMIT 25
),
vector_ranking AS (
    SELECT airport_code, 
           ROW_NUMBER() OVER (ORDER BY airport_code ASC) AS rank_vec
    FROM postgres_air.airport
    LIMIT 25
),
airport_stats AS (
    SELECT departure_airport AS airport_code,
           count(*)::bigint AS active_flights_count
    FROM postgres_air.flight
    WHERE scheduled_departure >= '2024-07-01 00:00:00+00'::timestamptz AND scheduled_departure < '2024-07-08 00:00:00+00'::timestamptz
    GROUP BY departure_airport
)
SELECT COALESCE(t.airport_code, v.airport_code)::character(3) AS airport_code,
       a.airport_name, 
       a.city,
       COALESCE(ast.active_flights_count, 0)::bigint AS active_flights_count,
       round((COALESCE(1.0 / (60 + t.rank_text), 0.0) + COALESCE(1.0 / (60 + v.rank_vec), 0.0))::numeric, 5)::numeric AS rrf_score
FROM text_ranking t
FULL OUTER JOIN vector_ranking v ON t.airport_code = v.airport_code
JOIN postgres_air.airport a ON a.airport_code = COALESCE(t.airport_code, v.airport_code)
LEFT JOIN airport_stats ast ON ast.airport_code = COALESCE(t.airport_code, v.airport_code)
ORDER BY rrf_score DESC
LIMIT 25;
