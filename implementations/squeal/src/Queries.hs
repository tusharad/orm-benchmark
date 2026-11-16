{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeOperators #-}

module Queries where

import Control.Monad.IO.Class (MonadIO (..))
import Data.ByteString (ByteString)
import qualified Data.ByteString.Char8 as BS8
import Data.Int (Int32, Int64)
import Data.Scientific (Scientific)
import Data.Text (Text)
import qualified Data.Text as T
import Data.Time (UTCTime)
import Squeal.PostgreSQL

import Models
import Schema

-- Helper to execute raw SQL statement
executeRaw :: (MonadIO pq, MonadPQ DB pq) => ByteString -> pq ()
executeRaw sql = manipulate_ (UnsafeManipulation sql)

-- HQ01: Massive Entity Deserialization (10,000 Rows)
hq01Query :: Query_ DB () Flight
hq01Query = select (DotStar #f)
  ( from (table ((#postgres_air ! #flight) `as` #f))
  & orderBy [#f ! #flight_id & Asc]
  & limit 10000
  )

-- HQ02: Wide Multi-Join Composite Hydration (5,000 Joined Rows)
hq02Query :: Query_ DB () CompositeRow
hq02Query = select_
  ( #b ! #booking_id `as` #booking_id
  :* #b ! #booking_ref `as` #booking_ref
  :* #b ! #email `as` #email
  :* #p ! #passenger_id `as` #passenger_id
  :* #p ! #first_name `as` #first_name
  :* #p ! #last_name `as` #last_name
  :* #bl ! #booking_leg_id `as` #booking_leg_id
  :* #bl ! #leg_num `as` #leg_num
  :* #f ! #flight_id `as` #flight_id
  :* #f ! #flight_no `as` #flight_no
  :* #f ! #scheduled_departure `as` #scheduled_departure
  :* #f ! #departure_airport `as` #departure_airport
  :* #f ! #arrival_airport `as` #arrival_airport
  )
  ( from (table ((#postgres_air ! #booking) `as` #b)
    & innerJoin (table ((#postgres_air ! #passenger) `as` #p))
        ((#p ! #booking_id & cast int8) .== #b ! #booking_id)
    & innerJoin (table ((#postgres_air ! #booking_leg) `as` #bl))
        ((#bl ! #booking_id & cast int8) .== #b ! #booking_id)
    & innerJoin (table ((#postgres_air ! #flight) `as` #f))
        (#f ! #flight_id .== #bl ! #flight_id)
    )
  & where_ (#b ! #booking_id .>= 100000 .&& #b ! #booking_id .<= 105000)
  & limit 5000
  )

-- HQ03: 4-Level Deep Entity Tree (Flight -> Legs -> Booking -> BoardingPass)
hq03Query :: Query_ DB () DeepTreeRow
hq03Query = select_
  ( #f ! #flight_id `as` #flight_id
  :* #f ! #flight_no `as` #flight_no
  :* #f ! #scheduled_departure `as` #scheduled_departure
  :* #bl ! #booking_leg_id `as` #booking_leg_id
  :* #bl ! #leg_num `as` #leg_num
  :* #b ! #booking_id `as` #booking_id
  :* #b ! #booking_ref `as` #booking_ref
  :* #bp ! #pass_id `as` #pass_id
  :* #bp ! #seat `as` #seat
  )
  ( from (table ((#postgres_air ! #flight) `as` #f)
    & innerJoin (table ((#postgres_air ! #booking_leg) `as` #bl))
        (#bl ! #flight_id .== #f ! #flight_id)
    & innerJoin (table ((#postgres_air ! #booking) `as` #b))
        ((#bl ! #booking_id & cast int8) .== #b ! #booking_id)
    & leftOuterJoin (table ((#postgres_air ! #boarding_pass) `as` #bp))
        ((#bp ! #booking_leg_id) .== (#bl ! #booking_leg_id & cast int8 & just_))
    )
  & where_ (#f ! #flight_id .>= 2000 .&& #f ! #flight_id .<= 2025)
  & limit 100
  )

-- HQ04: Account Relationship Graph
hq04Query :: Query_ DB () Account
hq04Query = select (DotStar #a)
  ( from (table ((#postgres_air ! #account) `as` #a))
  & where_ (#a ! #account_id .>= 1000 .&& #a ! #account_id .<= 1050)
  & limit 50
  )

-- HQ05: Fleet & Route Profitability Ledger
hq05RouteFinancialLedger :: (MonadIO pq, MonadPQ DB pq) => ByteString -> ByteString -> pq ()
hq05RouteFinancialLedger startDate endDate = executeRaw $
  "SELECT f.flight_no, f.departure_airport, f.arrival_airport, ac.model AS aircraft_model, " <>
  "count(DISTINCT f.flight_id) AS total_flights, count(DISTINCT b.booking_id) AS total_bookings, " <>
  "count(p.passenger_id) AS total_passengers, coalesce(sum(b.price), 0.0)::float8 AS gross_revenue, " <>
  "round(avg(b.price), 2)::float8 AS avg_ticket_price " <>
  "FROM postgres_air.flight f " <>
  "JOIN postgres_air.aircraft ac ON f.aircraft_code = ac.code " <>
  "JOIN postgres_air.booking_leg bl ON f.flight_id = bl.flight_id " <>
  "JOIN postgres_air.booking b ON bl.booking_id = b.booking_id " <>
  "LEFT JOIN postgres_air.passenger p ON b.booking_id = p.booking_id " <>
  "WHERE f.scheduled_departure >= '" <> startDate <> "'::timestamptz " <>
  "  AND f.scheduled_departure < '" <> endDate <> "'::timestamptz " <>
  "GROUP BY f.flight_no, f.departure_airport, f.arrival_airport, ac.model " <>
  "ORDER BY gross_revenue DESC, total_passengers DESC LIMIT 100"

-- HQ06: Chained Multi-Stage CTEs (Hub Centrality & Degree)
hq06HubCentralityDegree :: (MonadIO pq, MonadPQ DB pq) => ByteString -> ByteString -> pq ()
hq06HubCentralityDegree startDate endDate = executeRaw $
  "WITH flight_nodes AS ( " <>
  "    SELECT departure_airport AS hub, arrival_airport AS spoke, count(*)::int AS outbound_flights " <>
  "    FROM postgres_air.flight " <>
  "    WHERE scheduled_departure >= '" <> startDate <> "'::timestamptz " <>
  "      AND scheduled_departure < '" <> endDate <> "'::timestamptz " <>
  "    GROUP BY departure_airport, arrival_airport " <>
  "), " <>
  "hub_metrics AS ( " <>
  "    SELECT hub, count(DISTINCT spoke)::int AS degree_out, sum(outbound_flights)::bigint AS total_departures " <>
  "    FROM flight_nodes GROUP BY hub " <>
  "), " <>
  "ranked_hubs AS ( " <>
  "    SELECT hub, degree_out, total_departures, " <>
  "           dense_rank() OVER (ORDER BY total_departures DESC) AS departure_rank, " <>
  "           dense_rank() OVER (ORDER BY degree_out DESC) AS connectivity_rank " <>
  "    FROM hub_metrics " <>
  ") " <>
  "SELECT hub, degree_out, total_departures, departure_rank, connectivity_rank " <>
  "FROM ranked_hubs WHERE departure_rank <= 20 OR connectivity_rank <= 20 ORDER BY departure_rank ASC"

-- HQ07: Correlated At-Capacity Subquery + Loyalty Cross-Check
hq07AtCapacityLoyaltyCrossCheck :: (MonadIO pq, MonadPQ DB pq) => ByteString -> ByteString -> pq ()
hq07AtCapacityLoyaltyCrossCheck startDate endDate = executeRaw $
  "SELECT f.flight_id, f.flight_no, f.scheduled_departure, " <>
  "(SELECT count(*)::int FROM postgres_air.booking_leg bl WHERE bl.flight_id = f.flight_id) AS current_load, " <>
  "(SELECT avg(ff.award_points)::float8 FROM postgres_air.booking_leg bl2 " <>
  " JOIN postgres_air.passenger p ON bl2.booking_id = p.booking_id " <>
  " JOIN postgres_air.account a ON p.account_id = a.account_id " <>
  " JOIN postgres_air.frequent_flyer ff ON a.frequent_flyer_id = ff.frequent_flyer_id " <>
  " WHERE bl2.flight_id = f.flight_id) AS avg_vip_points " <>
  "FROM postgres_air.flight f " <>
  "WHERE f.scheduled_departure >= '" <> startDate <> "'::timestamptz " <>
  "  AND f.scheduled_departure < '" <> endDate <> "'::timestamptz " <>
  "  AND (SELECT count(*) FROM postgres_air.booking_leg bl3 WHERE bl3.flight_id = f.flight_id) > 20 " <>
  "ORDER BY current_load DESC LIMIT 50"

-- HQ08: Recursive Multi-Hop Flight Connection Graph (1-3 Hops)
hq08RecursiveFlightPathSearch :: (MonadIO pq, MonadPQ DB pq) => ByteString -> ByteString -> ByteString -> ByteString -> pq ()
hq08RecursiveFlightPathSearch origin dest startDate endDate = executeRaw $
  "WITH RECURSIVE flight_itinerary AS ( " <>
  "    SELECT flight_id, flight_no, departure_airport, arrival_airport, scheduled_departure, scheduled_arrival, " <>
  "           1 AS hops, ARRAY[departure_airport, arrival_airport]::text[] AS route " <>
  "    FROM postgres_air.flight " <>
  "    WHERE departure_airport = '" <> origin <> "' " <>
  "      AND scheduled_departure >= '" <> startDate <> "'::timestamptz " <>
  "      AND scheduled_departure < '" <> endDate <> "'::timestamptz " <>
  "    UNION ALL " <>
  "    SELECT next_f.flight_id, next_f.flight_no, next_f.departure_airport, next_f.arrival_airport, " <>
  "           next_f.scheduled_departure, next_f.scheduled_arrival, fi.hops + 1, fi.route || next_f.arrival_airport::text " <>
  "    FROM postgres_air.flight next_f " <>
  "    JOIN flight_itinerary fi ON next_f.departure_airport = fi.arrival_airport " <>
  "    WHERE next_f.scheduled_departure >= fi.scheduled_arrival + INTERVAL '1 hour' " <>
  "      AND next_f.scheduled_departure <= fi.scheduled_arrival + INTERVAL '6 hours' " <>
  "      AND fi.hops < 3 AND NOT (next_f.arrival_airport = ANY(fi.route)) " <>
  ") " <>
  "SELECT route, hops, scheduled_departure, scheduled_arrival " <>
  "FROM flight_itinerary WHERE arrival_airport = '" <> dest <> "' ORDER BY hops ASC, scheduled_arrival ASC LIMIT 20"

-- HQ09: Multi-Window Statistical Delay Dispersion & Cascades
hq09MultiWindowDelayDispersion :: (MonadIO pq, MonadPQ DB pq) => ByteString -> ByteString -> ByteString -> pq ()
hq09MultiWindowDelayDispersion airport startDate endDate = executeRaw $
  "SELECT flight_id, flight_no, scheduled_departure, actual_departure, " <>
  "coalesce(EXTRACT(EPOCH FROM (actual_departure - scheduled_departure)) / 60.0, 0.0)::float8 AS delay_minutes, " <>
  "avg(coalesce(EXTRACT(EPOCH FROM (actual_departure - scheduled_departure)) / 60.0, 0.0)) OVER ( " <>
  "    PARTITION BY departure_airport ORDER BY scheduled_departure ROWS BETWEEN 5 PRECEDING AND CURRENT ROW " <>
  ")::float8 AS moving_avg_delay, " <>
  "stddev(coalesce(EXTRACT(EPOCH FROM (actual_departure - scheduled_departure)) / 60.0, 0.0)) OVER ( " <>
  "    PARTITION BY departure_airport ORDER BY scheduled_departure ROWS BETWEEN 10 PRECEDING AND CURRENT ROW " <>
  ")::float8 AS stddev_delay, " <>
  "dense_rank() OVER ( " <>
  "    PARTITION BY departure_airport ORDER BY coalesce(EXTRACT(EPOCH FROM (actual_departure - scheduled_departure)), 0.0) DESC " <>
  ") AS delay_severity_rank " <>
  "FROM postgres_air.flight " <>
  "WHERE departure_airport = '" <> airport <> "' " <>
  "  AND scheduled_departure >= '" <> startDate <> "'::timestamptz " <>
  "  AND scheduled_departure < '" <> endDate <> "'::timestamptz " <>
  "ORDER BY scheduled_departure ASC LIMIT 100"

-- HQ10: Keyset (Cursor) Pagination over Composite Key
hq10Query :: Query_ DB (UTCTime, Int32) Flight
hq10Query = select (DotStar #f)
  ( from (table ((#postgres_air ! #flight) `as` #f))
  & where_ (#f ! #scheduled_departure .> param @1 .||
           (#f ! #scheduled_departure .== param @1 .&& #f ! #flight_id .> param @2))
  & orderBy [#f ! #scheduled_departure & Asc, #f ! #flight_id & Asc]
  & limit 50
  )

-- HQ11: Dynamic Faceted Search Engine
data FlightSearchParams = FlightSearchParams
  { origins :: Maybe [Text]
  , destinations :: Maybe [Text]
  , minDeparture :: Maybe UTCTime
  , maxDeparture :: Maybe UTCTime
  , aircraftClasses :: Maybe [Int32]
  , minRange :: Maybe Scientific
  , statuses :: Maybe [Text]
  , cursorTime :: Maybe UTCTime
  , cursorId :: Maybe Int32
  , limitRows :: Int64
  }

hq11DynamicSearch :: (MonadIO pq, MonadPQ DB pq) => FlightSearchParams -> pq ()
hq11DynamicSearch params = do
  let baseSql = "SELECT f.flight_id, f.flight_no, f.scheduled_departure, f.departure_airport, f.arrival_airport, ac.model, ac.class " <>
                "FROM postgres_air.flight f JOIN postgres_air.aircraft ac ON f.aircraft_code = ac.code WHERE 1=1"
      parts = [ baseSql
              , maybe "" (\os -> " AND f.departure_airport IN (" <> BS8.intercalate "," [ "'" <> BS8.pack (T.unpack o) <> "'" | o <- os ] <> ")") (origins params)
              , maybe "" (\ds -> " AND f.arrival_airport IN (" <> BS8.intercalate "," [ "'" <> BS8.pack (T.unpack d) <> "'" | d <- ds ] <> ")") (destinations params)
              , maybe "" (\_ -> " AND f.scheduled_departure >= '2024-07-01'::timestamptz") (minDeparture params)
              , maybe "" (\_ -> " AND f.scheduled_departure <= '2024-07-15'::timestamptz") (maxDeparture params)
              , maybe "" (\cs -> " AND ac.class IN (" <> BS8.intercalate "," [ BS8.pack (show c) | c <- cs ] <> ")") (aircraftClasses params)
              , maybe "" (\r -> " AND ac.range >= " <> BS8.pack (show r)) (minRange params)
              , maybe "" (\ss -> " AND f.status IN (" <> BS8.intercalate "," [ "'" <> BS8.pack (T.unpack s) <> "'" | s <- ss ] <> ")") (statuses params)
              , " ORDER BY f.scheduled_departure ASC, f.flight_id ASC LIMIT " <> BS8.pack (show (limitRows params))
              ]
  executeRaw (BS8.concat parts)

-- HQ12: High-Volume Batch Upsert (2,500 Records with Conflict Resolution)
hq12BatchUpsert :: (MonadIO pq, MonadPQ DB pq) => Int -> pq ()
hq12BatchUpsert count = do
  let rows = [ "(" <> BS8.pack (show i) <> ", 'Departed', clock_timestamp(), clock_timestamp(), clock_timestamp(), 1)" | i <- [1..count] ]
      sql = "INSERT INTO postgres_air.flight_status_update (flight_id, status, actual_departure, actual_arrival, update_ts, version) " <>
            "VALUES " <> BS8.intercalate ", " rows <> " " <>
            "ON CONFLICT (flight_id) DO UPDATE SET " <>
            "status = EXCLUDED.status, actual_departure = EXCLUDED.actual_departure, " <>
            "actual_arrival = EXCLUDED.actual_arrival, update_ts = EXCLUDED.update_ts, " <>
            "version = postgres_air.flight_status_update.version + 1"
  executeRaw sql

-- HQ13: Optimistic Concurrency Bulk Status Adjustment
hq13OptimisticBulkUpdate :: (MonadIO pq, MonadPQ DB pq) => Int32 -> Int32 -> Int32 -> Text -> pq ()
hq13OptimisticBulkUpdate minFid maxFid expectedVer newStatus = do
  let sql = "UPDATE postgres_air.flight " <>
            "SET status = '" <> BS8.pack (T.unpack newStatus) <> "', version = version + 1, update_ts = clock_timestamp() " <>
            "WHERE flight_id BETWEEN " <> BS8.pack (show minFid) <> " AND " <> BS8.pack (show maxFid) <> " AND version = " <> BS8.pack (show expectedVer)
  executeRaw sql

-- HQ14: High-Concurrency Seat Allocation Under Contention
hq14ReserveSeatConcurrent :: (MonadIO pq, MonadPQ DB pq) => Int32 -> Text -> pq ()
hq14ReserveSeatConcurrent flightId passengerName = do
  executeRaw "BEGIN"
  let selSql = "SELECT seat_no, version FROM postgres_air.flight_seat_inventory " <>
               "WHERE flight_id = " <> BS8.pack (show flightId) <> " AND status = 'AVAILABLE' LIMIT 1 FOR UPDATE"
  executeRaw selSql
  let updSql = "UPDATE postgres_air.flight_seat_inventory " <>
               "SET status = 'RESERVED', passenger_name = '" <> BS8.pack (T.unpack passengerName) <> "', reserved_at = clock_timestamp(), version = version + 1 " <>
               "WHERE flight_id = " <> BS8.pack (show flightId) <> " AND seat_no = '1A'"
  executeRaw updSql
  executeRaw "COMMIT"

-- HQ15: Distributed Financial / Points Transfer with Serialization Retry
hq15PointsTransferSerializable :: (MonadIO pq, MonadPQ DB pq) => Int32 -> Int32 -> Int32 -> pq ()
hq15PointsTransferSerializable fromAcc toAcc points = do
  executeRaw "BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE"
  executeRaw $ "UPDATE postgres_air.frequent_flyer SET award_points = award_points - " <> BS8.pack (show points) <> " WHERE frequent_flyer_id = " <> BS8.pack (show fromAcc)
  executeRaw $ "UPDATE postgres_air.frequent_flyer SET award_points = award_points + " <> BS8.pack (show points) <> " WHERE frequent_flyer_id = " <> BS8.pack (show toAcc)
  executeRaw "COMMIT"

-- HQ16: Multi-Modal Hybrid Vector Similarity + BM25 RRF Search
hq16HybridSearchRRF :: (MonadIO pq, MonadPQ DB pq) => ByteString -> ByteString -> pq ()
hq16HybridSearchRRF targetAirport queryText = executeRaw $
  "WITH text_ranking AS ( " <>
  "    SELECT airport_code, ROW_NUMBER() OVER (ORDER BY ts_rank_cd(search_tsv, plainto_tsquery('english', '" <> queryText <> "')) DESC) AS rank_text " <>
  "    FROM postgres_air.airport WHERE search_tsv @@ plainto_tsquery('english', '" <> queryText <> "') LIMIT 25 " <>
  "), " <>
  "vector_ranking AS ( " <>
  "    SELECT airport_code, ROW_NUMBER() OVER (ORDER BY (embedding <=> (SELECT embedding FROM postgres_air.airport WHERE airport_code = '" <> targetAirport <> "')) ASC) AS rank_vec " <>
  "    FROM postgres_air.airport LIMIT 25 " <>
  "), " <>
  "airport_stats AS ( " <>
  "    SELECT departure_airport AS airport_code, count(*)::bigint AS active_flights_count " <>
  "    FROM postgres_air.flight WHERE scheduled_departure >= '2024-07-01' AND scheduled_departure < '2024-07-15' GROUP BY departure_airport " <>
  "), " <>
  "rrf_scores AS ( " <>
  "    SELECT coalesce(t.airport_code, v.airport_code) AS airport_code, " <>
  "           (coalesce(1.0 / (60.0 + t.rank_text), 0.0) + coalesce(1.0 / (60.0 + v.rank_vec), 0.0))::float8 AS rrf_score " <>
  "    FROM text_ranking t FULL OUTER JOIN vector_ranking v ON t.airport_code = v.airport_code " <>
  ") " <>
  "SELECT a.airport_code, a.airport_name, a.city, coalesce(s.active_flights_count, 0)::bigint AS active_flights, round(r.rrf_score::numeric, 6)::float8 AS final_rrf_score " <>
  "FROM rrf_scores r JOIN postgres_air.airport a ON r.airport_code = a.airport_code LEFT JOIN airport_stats s ON a.airport_code = s.airport_code " <>
  "ORDER BY final_rrf_score DESC LIMIT 10"
