{-# LANGUAGE OverloadedStrings #-}

module Queries where

import Data.ByteString (ByteString)
import Data.Functor.Contravariant ((>$<))
import Data.Int (Int32)
import Data.Scientific (Scientific)
import Data.Text (Text)
import Data.Time (UTCTime)
import qualified Hasql.Decoders as D
import qualified Hasql.Encoders as E
import qualified Hasql.Statement as S

import Models

-- HQ01: Massive Entity Deserialization (10,000 Wide Rows)
hq01Stmt :: S.Statement () [Flight]
hq01Stmt = S.preparable sql E.noParams decoder
  where
    sql = "SELECT flight_id, flight_no, scheduled_departure, scheduled_arrival, \
          \departure_airport::text AS departure_airport, arrival_airport::text AS arrival_airport, \
          \status, aircraft_code::text AS aircraft_code, \
          \actual_departure, actual_arrival, update_ts, version \
          \FROM postgres_air.flight ORDER BY flight_id LIMIT 10000;"
    decoder = D.rowList $ Flight
      <$> D.column (D.nonNullable D.int4)
      <*> D.column (D.nonNullable D.text)
      <*> D.column (D.nonNullable D.timestamptz)
      <*> D.column (D.nonNullable D.timestamptz)
      <*> D.column (D.nonNullable D.text)
      <*> D.column (D.nonNullable D.text)
      <*> D.column (D.nonNullable D.text)
      <*> D.column (D.nonNullable D.text)
      <*> D.column (D.nullable D.timestamptz)
      <*> D.column (D.nullable D.timestamptz)
      <*> D.column (D.nullable D.timestamptz)
      <*> D.column (D.nonNullable D.int4)

-- HQ02: Wide Multi-Join Composite Hydration (5,000 Joined Records Across 4 Relations)
hq02Stmt :: S.Statement () [CompositeBookingRecord]
hq02Stmt = S.preparable sql E.noParams decoder
  where
    sql = "SELECT b.booking_id, b.booking_ref, b.price, b.email, \
          \p.passenger_id, p.first_name, p.last_name, p.age, \
          \bl.booking_leg_id, bl.leg_num, bl.is_returning, \
          \f.flight_id, f.flight_no, f.departure_airport::text AS departure_airport, f.arrival_airport::text AS arrival_airport, \
          \f.scheduled_departure, f.status \
          \FROM postgres_air.booking b \
          \JOIN postgres_air.passenger p ON b.booking_id = p.booking_id \
          \JOIN postgres_air.booking_leg bl ON b.booking_id = bl.booking_id \
          \JOIN postgres_air.flight f ON bl.flight_id = f.flight_id \
          \WHERE b.booking_id BETWEEN 100000 AND 105000 \
          \ORDER BY b.booking_id ASC, p.passenger_id ASC, bl.booking_leg_id ASC \
          \LIMIT 5000;"
    decoder = D.rowList $ CompositeBookingRecord
      <$> D.column (D.nonNullable D.int8)
      <*> D.column (D.nonNullable D.text)
      <*> D.column (D.nullable D.numeric)
      <*> D.column (D.nonNullable D.text)
      <*> D.column (D.nonNullable D.int4)
      <*> D.column (D.nonNullable D.text)
      <*> D.column (D.nonNullable D.text)
      <*> D.column (D.nullable D.int4)
      <*> D.column (D.nonNullable D.int4)
      <*> D.column (D.nullable D.int4)
      <*> D.column (D.nullable D.bool)
      <*> D.column (D.nonNullable D.int4)
      <*> D.column (D.nonNullable D.text)
      <*> D.column (D.nonNullable D.text)
      <*> D.column (D.nonNullable D.text)
      <*> D.column (D.nonNullable D.timestamptz)
      <*> D.column (D.nonNullable D.text)

-- HQ03: 4-Level Deep Hierarchical Entity Tree Materialization
hq03Stmt :: S.Statement () [(Int32, Text, Int32, Maybe Int32)]
hq03Stmt = S.preparable sql E.noParams decoder
  where
    sql = "SELECT f.flight_id, f.flight_no, bl.booking_leg_id, bp.pass_id \
          \FROM postgres_air.flight f \
          \JOIN postgres_air.booking_leg bl ON f.flight_id = bl.flight_id \
          \JOIN postgres_air.booking b ON bl.booking_id = b.booking_id \
          \LEFT JOIN postgres_air.boarding_pass bp ON bl.booking_leg_id = bp.booking_leg_id \
          \WHERE f.flight_id BETWEEN 2000 AND 2025 \
          \ORDER BY f.flight_id ASC, bl.booking_leg_id ASC, COALESCE(bp.pass_id, 0) ASC;"
    decoder = D.rowList $ (,,,)
      <$> D.column (D.nonNullable D.int4)
      <*> D.column (D.nonNullable D.text)
      <*> D.column (D.nonNullable D.int4)
      <*> D.column (D.nullable D.int4)

-- HQ04: Account Relationship Graph with Optional Sub-Entities
hq04Stmt :: S.Statement () [AccountDetail]
hq04Stmt = S.preparable sql E.noParams decoder
  where
    sql = "SELECT a.account_id, a.login, a.first_name, a.last_name, \
          \ff.level, ff.award_points, \
          \ph.phone_id, ph.phone, ph.phone_type, \
          \b.booking_id, b.booking_ref, b.price, \
          \p.passenger_id, p.first_name, p.last_name \
          \FROM postgres_air.account a \
          \LEFT JOIN postgres_air.frequent_flyer ff ON a.frequent_flyer_id = ff.frequent_flyer_id \
          \LEFT JOIN postgres_air.phone ph ON a.account_id = ph.account_id \
          \LEFT JOIN postgres_air.booking b ON a.account_id = b.account_id \
          \LEFT JOIN postgres_air.passenger p ON b.booking_id = p.booking_id \
          \WHERE a.account_id BETWEEN 50000 AND 50200 \
          \ORDER BY a.account_id, COALESCE(ph.phone_id, 0), COALESCE(b.booking_id, 0), COALESCE(p.passenger_id, 0) \
          \LIMIT 7000;"
    decoder = D.rowList $ AccountDetail
      <$> D.column (D.nonNullable D.int4)
      <*> D.column (D.nonNullable D.text)
      <*> D.column (D.nonNullable D.text)
      <*> D.column (D.nonNullable D.text)
      <*> D.column (D.nullable D.int4)
      <*> D.column (D.nullable D.int4)
      <*> D.column (D.nullable D.int4)
      <*> D.column (D.nullable D.text)
      <*> D.column (D.nullable D.text)
      <*> D.column (D.nullable D.int8)
      <*> D.column (D.nullable D.text)
      <*> D.column (D.nullable D.numeric)
      <*> D.column (D.nullable D.int4)
      <*> D.column (D.nullable D.text)
      <*> D.column (D.nullable D.text)

-- HQ05: Fleet & Route Profitability Analytical Ledger (5-Table Join over 400k+ Rows)
hq05Stmt :: S.Statement () [RouteProfitability]
hq05Stmt = S.preparable sql E.noParams decoder
  where
    sql = "SELECT orig.airport_code::text AS origin, \
          \dest.airport_code::text AS destination, \
          \ac.model AS aircraft_model, \
          \count(DISTINCT f.flight_id) AS total_flights, \
          \count(bl.booking_leg_id) AS total_legs_booked, \
          \round(sum(b.price)::numeric, 2) AS total_revenue, \
          \round(avg(EXTRACT(EPOCH FROM (f.actual_departure - f.scheduled_departure)) / 60)::numeric, 2) AS avg_delay_minutes, \
          \round(100.0 * count(CASE WHEN f.actual_departure <= f.scheduled_departure + INTERVAL '15 minutes' THEN 1 END) / count(f.flight_id), 2) AS on_time_pct \
          \FROM postgres_air.flight f \
          \JOIN postgres_air.airport orig ON f.departure_airport = orig.airport_code \
          \JOIN postgres_air.airport dest ON f.arrival_airport = dest.airport_code \
          \JOIN postgres_air.aircraft ac ON f.aircraft_code = ac.code \
          \JOIN postgres_air.booking_leg bl ON f.flight_id = bl.flight_id \
          \JOIN postgres_air.booking b ON bl.booking_id = b.booking_id \
          \WHERE f.scheduled_departure >= '2024-07-01 00:00:00+00' AND f.scheduled_departure < '2024-07-04 00:00:00+00' \
          \GROUP BY orig.airport_code, dest.airport_code, ac.model \
          \HAVING count(DISTINCT f.flight_id) >= 3 \
          \ORDER BY total_revenue DESC \
          \LIMIT 50;"
    decoder = D.rowList $ RouteProfitability
      <$> D.column (D.nonNullable D.text)
      <*> D.column (D.nonNullable D.text)
      <*> D.column (D.nullable D.text)
      <*> D.column (D.nonNullable D.int8)
      <*> D.column (D.nonNullable D.int8)
      <*> D.column (D.nullable D.numeric)
      <*> D.column (D.nullable D.numeric)
      <*> D.column (D.nullable D.numeric)

-- HQ06: Chained Multi-Stage CTEs (Airport Hub Centrality & Network Degree)
hq06Stmt :: S.Statement () [HubCentrality]
hq06Stmt = S.preparable sql E.noParams decoder
  where
    sql = "WITH flight_volumes AS ( \
          \    SELECT departure_airport::text AS airport_code, \
          \           count(*) AS departures_count, \
          \           round(avg(EXTRACT(EPOCH FROM (actual_departure - scheduled_departure)) / 60)::numeric, 2) AS avg_dep_delay \
          \    FROM postgres_air.flight \
          \    WHERE scheduled_departure >= '2024-06-01 00:00:00+00' AND scheduled_departure < '2024-07-01 00:00:00+00' \
          \      AND actual_departure IS NOT NULL \
          \    GROUP BY departure_airport \
          \), \
          \arrival_volumes AS ( \
          \    SELECT arrival_airport::text AS airport_code, \
          \           count(*) AS arrivals_count, \
          \           round(avg(EXTRACT(EPOCH FROM (actual_arrival - scheduled_arrival)) / 60)::numeric, 2) AS avg_arr_delay \
          \    FROM postgres_air.flight \
          \    WHERE scheduled_arrival >= '2024-06-01 00:00:00+00' AND scheduled_arrival < '2024-07-01 00:00:00+00' \
          \      AND actual_arrival IS NOT NULL \
          \    GROUP BY arrival_airport \
          \), \
          \route_connectivity AS ( \
          \    SELECT departure_airport::text AS airport_code, \
          \           count(DISTINCT arrival_airport) AS unique_destinations, \
          \           count(DISTINCT aircraft_code) AS fleet_diversity \
          \    FROM postgres_air.flight \
          \    WHERE scheduled_departure >= '2024-06-01 00:00:00+00' AND scheduled_departure < '2024-07-01 00:00:00+00' \
          \    GROUP BY departure_airport \
          \) \
          \SELECT a.airport_code::text AS airport_code, \
          \       a.airport_name, \
          \       a.city, \
          \       coalesce(fv.departures_count, 0) AS total_departures, \
          \       coalesce(av.arrivals_count, 0) AS total_arrivals, \
          \       coalesce(rc.unique_destinations, 0) AS unique_destinations, \
          \       coalesce(rc.fleet_diversity, 0) AS fleet_diversity, \
          \       coalesce(fv.avg_dep_delay, 0) AS avg_dep_delay, \
          \       coalesce(av.avg_arr_delay, 0) AS avg_arr_delay, \
          \       round( \
          \           (coalesce(fv.departures_count, 0) + coalesce(av.arrivals_count, 0)) * \
          \           (1.0 + coalesce(rc.unique_destinations, 0) / 100.0) / \
          \           (1.0 + greatest(coalesce(fv.avg_dep_delay, 0), 0) / 10.0), \
          \           2 \
          \       ) AS hub_centrality_score \
          \FROM postgres_air.airport a \
          \JOIN flight_volumes fv ON a.airport_code = fv.airport_code \
          \JOIN arrival_volumes av ON a.airport_code = av.airport_code \
          \JOIN route_connectivity rc ON a.airport_code = rc.airport_code \
          \ORDER BY hub_centrality_score DESC \
          \LIMIT 50;"
    decoder = D.rowList $ HubCentrality
      <$> D.column (D.nonNullable D.text)
      <*> D.column (D.nonNullable D.text)
      <*> D.column (D.nonNullable D.text)
      <*> D.column (D.nonNullable D.int8)
      <*> D.column (D.nonNullable D.int8)
      <*> D.column (D.nonNullable D.int8)
      <*> D.column (D.nonNullable D.int8)
      <*> D.column (D.nonNullable D.numeric)
      <*> D.column (D.nonNullable D.numeric)
      <*> D.column (D.nonNullable D.numeric)

-- HQ07: Correlated At-Capacity Subquery with Loyalty Tier Cross-Check
hq07Stmt :: S.Statement () [FlightCapacity]
hq07Stmt = S.preparable sql E.noParams decoder
  where
    sql = "SELECT f.flight_id, f.flight_no, f.departure_airport::text AS departure_airport, f.arrival_airport::text AS arrival_airport, f.scheduled_departure, \
          \ac.model AS aircraft_model, ac.range AS aircraft_range, \
          \(SELECT count(*) FROM postgres_air.booking_leg bl WHERE bl.flight_id = f.flight_id) AS seats_booked, \
          \(SELECT count(*) FROM postgres_air.booking_leg bl \
          \ JOIN postgres_air.passenger p ON bl.booking_id = p.booking_id \
          \ JOIN postgres_air.account a ON p.account_id = a.account_id \
          \ JOIN postgres_air.frequent_flyer ff ON a.frequent_flyer_id = ff.frequent_flyer_id \
          \ WHERE bl.flight_id = f.flight_id AND ff.level >= 3) AS elite_flyer_count \
          \FROM postgres_air.flight f \
          \JOIN postgres_air.aircraft ac ON f.aircraft_code = ac.code \
          \WHERE f.scheduled_departure >= '2024-07-01 00:00:00+00' AND f.scheduled_departure < '2024-07-03 00:00:00+00' \
          \  AND ac.class >= 2 \
          \  AND (SELECT count(*) FROM postgres_air.booking_leg bl WHERE bl.flight_id = f.flight_id) > 40 \
          \  AND EXISTS ( \
          \      SELECT 1 FROM postgres_air.flight route_f \
          \      WHERE route_f.departure_airport = f.departure_airport \
          \        AND route_f.arrival_airport = f.arrival_airport \
          \        AND route_f.status = 'Canceled' \
          \        AND route_f.scheduled_departure >= '2024-06-01 00:00:00+00' \
          \  ) \
          \ORDER BY seats_booked DESC \
          \LIMIT 100;"
    decoder = D.rowList $ FlightCapacity
      <$> D.column (D.nonNullable D.int4)
      <*> D.column (D.nonNullable D.text)
      <*> D.column (D.nonNullable D.text)
      <*> D.column (D.nonNullable D.text)
      <*> D.column (D.nonNullable D.timestamptz)
      <*> D.column (D.nullable D.text)
      <*> D.column (D.nonNullable D.numeric)
      <*> D.column (D.nonNullable D.int8)
      <*> D.column (D.nonNullable D.int8)

-- HQ08: Recursive Multi-Hop Flight Connection Graph Search (1- to 3-Hop Paths)
hq08Stmt :: S.Statement () [Itinerary]
hq08Stmt = S.preparable sql E.noParams decoder
  where
    sql = "WITH RECURSIVE flight_paths AS ( \
          \    SELECT f.flight_id, \
          \           f.departure_airport::text AS departure_airport, \
          \           f.arrival_airport::text AS arrival_airport, \
          \           f.scheduled_departure, \
          \           f.scheduled_arrival, \
          \           1 AS hops, \
          \           ARRAY[f.departure_airport::text, f.arrival_airport::text] AS route_airports, \
          \           ARRAY[f.flight_id] AS route_flights, \
          \           f.scheduled_departure AS journey_start, \
          \           f.scheduled_arrival AS journey_end, \
          \           (EXTRACT(EPOCH FROM (f.scheduled_arrival - f.scheduled_departure)) / 60)::numeric(10,2) AS total_flight_minutes \
          \    FROM postgres_air.flight f \
          \    WHERE f.departure_airport = 'JFK' \
          \      AND f.scheduled_departure >= '2024-07-05 00:00:00+00' \
          \      AND f.scheduled_departure < '2024-07-06 00:00:00+00' \
          \    UNION ALL \
          \    SELECT next_f.flight_id, \
          \           fp.departure_airport, \
          \           next_f.arrival_airport::text, \
          \           next_f.scheduled_departure, \
          \           next_f.scheduled_arrival, \
          \           fp.hops + 1, \
          \           fp.route_airports || next_f.arrival_airport::text, \
          \           fp.route_flights || next_f.flight_id, \
          \           fp.journey_start, \
          \           next_f.scheduled_arrival, \
          \           (fp.total_flight_minutes + (EXTRACT(EPOCH FROM (next_f.scheduled_arrival - next_f.scheduled_departure)) / 60))::numeric(10,2) \
          \    FROM flight_paths fp \
          \    JOIN postgres_air.flight next_f ON fp.arrival_airport = next_f.departure_airport \
          \    WHERE fp.hops < 3 \
          \      AND next_f.scheduled_departure >= fp.scheduled_arrival + INTERVAL '60 minutes' \
          \      AND next_f.scheduled_departure <= fp.scheduled_arrival + INTERVAL '360 minutes' \
          \      AND NOT (next_f.arrival_airport::text = ANY(fp.route_airports)) \
          \) \
          \SELECT hops, \
          \       array_to_string(route_airports, ' -> ') AS route, \
          \       journey_start, \
          \       journey_end, \
          \       (EXTRACT(EPOCH FROM (journey_end - journey_start)) / 60)::numeric(10,2) AS total_elapsed_minutes, \
          \       total_flight_minutes \
          \FROM flight_paths \
          \WHERE arrival_airport = 'ORD' \
          \ORDER BY hops ASC, total_elapsed_minutes ASC \
          \LIMIT 25;"
    decoder = D.rowList $ Itinerary
      <$> D.column (D.nonNullable D.int4)
      <*> D.column (D.nonNullable D.text)
      <*> D.column (D.nonNullable D.timestamptz)
      <*> D.column (D.nonNullable D.timestamptz)
      <*> D.column (D.nullable D.numeric)
      <*> D.column (D.nullable D.numeric)

-- HQ09: Multi-Window Statistical Delay Dispersion & Cascades
hq09Stmt :: S.Statement () [WindowDelay]
hq09Stmt = S.preparable sql E.noParams decoder
  where
    sql = "WITH flight_delays AS ( \
          \    SELECT flight_id, \
          \           flight_no, \
          \           departure_airport::text AS departure_airport, \
          \           arrival_airport::text AS arrival_airport, \
          \           scheduled_departure, \
          \           actual_departure, \
          \           round((EXTRACT(EPOCH FROM (actual_departure - scheduled_departure)) / 60)::numeric, 2) AS delay_minutes \
          \    FROM postgres_air.flight \
          \    WHERE departure_airport = 'ORD' \
          \      AND actual_departure IS NOT NULL \
          \      AND scheduled_departure >= '2024-06-01 00:00:00+00' \
          \      AND scheduled_departure < '2024-07-01 00:00:00+00' \
          \), \
          \window_calculations AS ( \
          \    SELECT flight_id, \
          \           flight_no, \
          \           arrival_airport, \
          \           scheduled_departure, \
          \           delay_minutes, \
          \           round(avg(delay_minutes) OVER ( \
          \               PARTITION BY departure_airport, arrival_airport \
          \               ORDER BY scheduled_departure \
          \               ROWS BETWEEN 4 PRECEDING AND CURRENT ROW \
          \           ), 2) AS rolling_avg_delay_5, \
          \           delay_minutes - lag(delay_minutes, 1) OVER ( \
          \               PARTITION BY departure_airport, arrival_airport \
          \               ORDER BY scheduled_departure \
          \           ) AS delay_diff_prev, \
          \           round(coalesce(stddev_samp(delay_minutes) OVER ( \
          \               PARTITION BY departure_airport, arrival_airport \
          \               ORDER BY scheduled_departure \
          \               ROWS BETWEEN 9 PRECEDING AND CURRENT ROW \
          \           ), 0), 2) AS rolling_stddev_10, \
          \           dense_rank() OVER ( \
          \               PARTITION BY departure_airport, arrival_airport \
          \               ORDER BY delay_minutes DESC \
          \           ) AS severity_rank \
          \    FROM flight_delays \
          \) \
          \SELECT flight_id, flight_no, arrival_airport, scheduled_departure, \
          \       delay_minutes, rolling_avg_delay_5, delay_diff_prev, rolling_stddev_10, severity_rank \
          \FROM window_calculations \
          \ORDER BY arrival_airport, scheduled_departure \
          \LIMIT 5000;"
    decoder = D.rowList $ WindowDelay
      <$> D.column (D.nonNullable D.int4)
      <*> D.column (D.nonNullable D.text)
      <*> D.column (D.nonNullable D.text)
      <*> D.column (D.nonNullable D.timestamptz)
      <*> D.column (D.nullable D.numeric)
      <*> D.column (D.nullable D.numeric)
      <*> D.column (D.nullable D.numeric)
      <*> D.column (D.nullable D.numeric)
      <*> D.column (D.nonNullable D.int8)

-- HQ10: High-Throughput Keyset (Cursor) Pagination over Composite Tuple
hq10Stmt :: S.Statement (UTCTime, Int32) [Flight]
hq10Stmt = S.preparable sql encoder decoder
  where
    sql = "SELECT flight_id, flight_no, scheduled_departure, scheduled_arrival, \
          \departure_airport::text AS departure_airport, arrival_airport::text AS arrival_airport, \
          \status, aircraft_code::text AS aircraft_code, \
          \actual_departure, actual_arrival, update_ts, version \
          \FROM postgres_air.flight \
          \WHERE scheduled_departure > $1 OR (scheduled_departure = $1 AND flight_id > $2) \
          \ORDER BY scheduled_departure ASC, flight_id ASC \
          \LIMIT 50;"
    encoder = (fst >$< E.param (E.nonNullable E.timestamptz))
           <> (snd >$< E.param (E.nonNullable E.int4))
    decoder = D.rowList $ Flight
      <$> D.column (D.nonNullable D.int4)
      <*> D.column (D.nonNullable D.text)
      <*> D.column (D.nonNullable D.timestamptz)
      <*> D.column (D.nonNullable D.timestamptz)
      <*> D.column (D.nonNullable D.text)
      <*> D.column (D.nonNullable D.text)
      <*> D.column (D.nonNullable D.text)
      <*> D.column (D.nonNullable D.text)
      <*> D.column (D.nullable D.timestamptz)
      <*> D.column (D.nullable D.timestamptz)
      <*> D.column (D.nullable D.timestamptz)
      <*> D.column (D.nonNullable D.int4)

-- HQ11: High-Dimensional Dynamic Faceted Flight Search Engine (10 Optional Predicates)
hq11Stmt :: S.Statement () [FacetedFlight]
hq11Stmt = S.preparable sql E.noParams decoder
  where
    sql = "SELECT f.flight_id, f.flight_no, f.departure_airport::text AS departure_airport, f.arrival_airport::text AS arrival_airport, \
          \f.scheduled_departure, f.scheduled_arrival, f.status, \
          \ac.model, ac.range, ac.class \
          \FROM postgres_air.flight f \
          \JOIN postgres_air.aircraft ac ON f.aircraft_code = ac.code \
          \WHERE f.departure_airport IN ('JFK', 'BOS', 'EWR') \
          \  AND f.arrival_airport IN ('LAX', 'SFO', 'SEA') \
          \  AND f.scheduled_departure >= '2024-07-01 00:00:00+00' \
          \  AND f.scheduled_departure <= '2024-07-15 23:59:59+00' \
          \  AND ac.class IN (1, 2, 3) \
          \  AND ac.range >= 2000 \
          \  AND f.status IN ('On time', 'Delayed') \
          \  AND EXTRACT(HOUR FROM f.scheduled_departure) BETWEEN 6 AND 21 \
          \  AND (f.scheduled_departure > '2024-07-01 06:00:00+00' OR (f.scheduled_departure = '2024-07-01 06:00:00+00' AND f.flight_id > 500)) \
          \ORDER BY f.scheduled_departure ASC, f.flight_id ASC \
          \LIMIT 100;"
    decoder = D.rowList $ FacetedFlight
      <$> D.column (D.nonNullable D.int4)
      <*> D.column (D.nonNullable D.text)
      <*> D.column (D.nonNullable D.text)
      <*> D.column (D.nonNullable D.text)
      <*> D.column (D.nonNullable D.timestamptz)
      <*> D.column (D.nonNullable D.timestamptz)
      <*> D.column (D.nonNullable D.text)
      <*> D.column (D.nullable D.text)
      <*> D.column (D.nonNullable D.numeric)
      <*> D.column (D.nonNullable D.int4)

-- HQ12: High-Volume Batch Upsert (2,500 Records with Conflict Resolution)
hq12Stmt :: Text -> S.Statement () ()
hq12Stmt rawSql = S.unpreparable rawSql E.noParams D.noResult

-- HQ13: Optimistic Concurrency Bulk Fare & Status Adjustment
hq13UpdateStmt :: S.Statement () ()
hq13UpdateStmt = S.unpreparable sql E.noParams D.noResult
  where
    sql = "UPDATE postgres_air.flight \
          \SET status = 'Boarding', version = version + 1, update_ts = NOW() \
          \WHERE flight_id BETWEEN 1000 AND 1050 AND version = 1;"

hq13ResetStmt :: S.Statement () ()
hq13ResetStmt = S.unpreparable sql E.noParams D.noResult
  where
    sql = "UPDATE postgres_air.flight \
          \SET status = 'Departed', version = 1 \
          \WHERE flight_id BETWEEN 1000 AND 1050;"

-- HQ14: High-Concurrency Seat Allocation Under Contention (C=100)
hq14SelectSeatStmt :: S.Statement Int32 (Maybe (Text, Int32))
hq14SelectSeatStmt = S.preparable sql (E.param (E.nonNullable E.int4)) decoder
  where
    sql = "SELECT seat_no, version FROM postgres_air.flight_seat_inventory \
          \WHERE flight_id = $1 AND status = 'AVAILABLE' LIMIT 1 FOR UPDATE;"
    decoder = D.rowMaybe $ (,)
      <$> D.column (D.nonNullable D.text)
      <*> D.column (D.nonNullable D.int4)

hq14ReserveSeatStmt :: S.Statement (Int32, Text, Int32) ()
hq14ReserveSeatStmt = S.preparable sql encoder D.noResult
  where
    sql = "UPDATE postgres_air.flight_seat_inventory \
          \SET status = 'RESERVED', passenger_name = 'Test Concurrent Flyer', reserved_at = NOW(), version = version + 1 \
          \WHERE flight_id = $1 AND seat_no = $2 AND version = $3;"
    encoder = ((\(fId, _, _) -> fId) >$< E.param (E.nonNullable E.int4))
           <> ((\(_, seat, _) -> seat) >$< E.param (E.nonNullable E.text))
           <> ((\(_, _, ver) -> ver) >$< E.param (E.nonNullable E.int4))

-- HQ15: Distributed Financial Points Transfer
hq15DebitStmt :: S.Statement (Int32, Int32) ()
hq15DebitStmt = S.preparable sql encoder D.noResult
  where
    sql = "UPDATE postgres_air.frequent_flyer SET award_points = award_points - $2 WHERE frequent_flyer_id = $1;"
    encoder = (fst >$< E.param (E.nonNullable E.int4))
           <> (snd >$< E.param (E.nonNullable E.int4))

hq15CreditStmt :: S.Statement (Int32, Int32) ()
hq15CreditStmt = S.preparable sql encoder D.noResult
  where
    sql = "UPDATE postgres_air.frequent_flyer SET award_points = award_points + $2 WHERE frequent_flyer_id = $1;"
    encoder = (fst >$< E.param (E.nonNullable E.int4))
           <> (snd >$< E.param (E.nonNullable E.int4))

-- HQ16: Multi-Modal Hybrid Vector Similarity + BM25 RRF Search
hq16Stmt :: S.Statement () [HybridAirport]
hq16Stmt = S.preparable sql E.noParams decoder
  where
    sql = "WITH text_ranking AS ( \
          \    SELECT airport_code, \
          \           ROW_NUMBER() OVER (ORDER BY ts_rank_cd(search_tsv, plainto_tsquery('english', 'London Heathrow international hub')) DESC) AS rank_text \
          \    FROM postgres_air.airport \
          \    WHERE search_tsv @@ plainto_tsquery('english', 'London Heathrow international hub') \
          \    LIMIT 25 \
          \), \
          \vector_ranking AS ( \
          \    SELECT airport_code, \
          \           ROW_NUMBER() OVER (ORDER BY (embedding <=> (SELECT embedding FROM postgres_air.airport WHERE airport_code = 'LHR')) ASC) AS rank_vec \
          \    FROM postgres_air.airport \
          \    LIMIT 25 \
          \), \
          \airport_stats AS ( \
          \    SELECT departure_airport AS airport_code, \
          \           count(*) AS active_flights_count \
          \    FROM postgres_air.flight \
          \    WHERE scheduled_departure >= '2024-07-01 00:00:00+00' AND scheduled_departure < '2024-07-08 00:00:00+00' \
          \    GROUP BY departure_airport \
          \) \
          \SELECT COALESCE(t.airport_code, v.airport_code)::text AS airport_code, \
          \       a.airport_name, \
          \       a.city, \
          \       COALESCE(ast.active_flights_count, 0) AS active_flights_count, \
          \       round((COALESCE(1.0 / (60 + t.rank_text), 0.0) + COALESCE(1.0 / (60 + v.rank_vec), 0.0))::numeric, 5) AS rrf_score \
          \FROM text_ranking t \
          \FULL OUTER JOIN vector_ranking v ON t.airport_code = v.airport_code \
          \JOIN postgres_air.airport a ON a.airport_code = COALESCE(t.airport_code, v.airport_code) \
          \LEFT JOIN airport_stats ast ON ast.airport_code = COALESCE(t.airport_code, v.airport_code) \
          \ORDER BY rrf_score DESC \
          \LIMIT 25;"
    decoder = D.rowList $ HybridAirport
      <$> D.column (D.nonNullable D.text)
      <*> D.column (D.nonNullable D.text)
      <*> D.column (D.nonNullable D.text)
      <*> D.column (D.nonNullable D.int8)
      <*> D.column (D.nonNullable D.numeric)
