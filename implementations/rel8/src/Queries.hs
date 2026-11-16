{-# language BlockArguments #-}
{-# language DeriveAnyClass #-}
{-# language DeriveGeneric #-}
{-# language DerivingStrategies #-}
{-# language DuplicateRecordFields #-}
{-# language OverloadedRecordDot #-}
{-# language OverloadedStrings #-}
{-# language StandaloneDeriving #-}
{-# language TypeFamilies #-}

module Queries where

import Control.Concurrent (threadDelay)
import Control.Exception (Exception, throwIO, try)
import Data.ByteString (ByteString)
import qualified Data.ByteString.Char8 as BS8
import Data.Functor.Contravariant ((>$<))
import Data.Int (Int32, Int64)
import Data.Scientific (Scientific)
import Data.Text (Text)
import qualified Data.Text as T
import Data.Time (UTCTime)
import qualified Data.Vector as V
import GHC.Generics (Generic)
import qualified Hasql.Connection as Hasql
import qualified Hasql.Decoders as Decoders
import qualified Hasql.Encoders as Encoders
import qualified Hasql.Session as Hasql
import qualified Hasql.Statement as Hasql
import Rel8
import qualified Rel8.Expr.Num as Rel8Num
import Schema

-- Composite Row for HQ02
data CompositeRow f = CompositeRow
  { bookingId :: Column f Int64
  , bookingRef :: Column f Text
  , email :: Column f Text
  , passengerId :: Column f Int32
  , firstName :: Column f Text
  , lastName :: Column f Text
  , bookingLegId :: Column f Int32
  , legNum :: Column f (Maybe Int32)
  , flightId :: Column f Int32
  , flightNo :: Column f Text
  , scheduledDeparture :: Column f UTCTime
  , departureAirport :: Column f Text
  , arrivalAirport :: Column f Text
  }
  deriving stock (Generic)
  deriving anyclass (Rel8able)

deriving stock instance f ~ Result => Show (CompositeRow f)
deriving stock instance f ~ Result => Eq (CompositeRow f)

-- HQ01: Massive Entity Deserialization (10k Wide Rows)
hq01MassiveDeserialization :: Query (Flight Expr)
hq01MassiveDeserialization = limit 10000 $ orderBy ((\f -> f.flightId) >$< asc) $ each flightSchema

-- HQ02: Wide Multi-Join Composite Hydration (5k Joined Rows)
hq02WideMultiJoin :: Query (CompositeRow Expr)
hq02WideMultiJoin = limit 5000 $ do
  b <- each bookingSchema
  where_ (b.bookingId >=. 100000 &&. b.bookingId <=. 105000)
  p <- each passengerSchema
  where_ (Rel8Num.fromIntegral p.bookingId ==. b.bookingId)
  bl <- each bookingLegSchema
  where_ (Rel8Num.fromIntegral bl.bookingId ==. b.bookingId)
  f <- each flightSchema
  where_ (f.flightId ==. bl.flightId)
  pure CompositeRow
    { bookingId = b.bookingId
    , bookingRef = b.bookingRef
    , email = b.email
    , passengerId = p.passengerId
    , firstName = p.firstName
    , lastName = p.lastName
    , bookingLegId = bl.bookingLegId
    , legNum = bl.legNum
    , flightId = f.flightId
    , flightNo = f.flightNo
    , scheduledDeparture = f.scheduledDeparture
    , departureAirport = f.departureAirport
    , arrivalAirport = f.arrivalAirport
    }

-- HQ03: 4-Level Deep Entity Tree (Flight -> Legs -> Booking -> Pass)
data DeepTreeRow f = DeepTreeRow
  { flightId :: Column f Int32
  , flightNo :: Column f Text
  , scheduledDeparture :: Column f UTCTime
  , bookingLegId :: Column f Int32
  , legNum :: Column f (Maybe Int32)
  , bookingId :: Column f Int64
  , bookingRef :: Column f Text
  , passId :: Column f (Maybe Int32)
  , seat :: Column f (Maybe Text)
  }
  deriving stock (Generic)
  deriving anyclass (Rel8able)

deriving stock instance f ~ Result => Show (DeepTreeRow f)

hq03DeepHierarchicalGraph :: Query (DeepTreeRow Expr)
hq03DeepHierarchicalGraph = limit 100 $ do
  f <- each flightSchema
  where_ (f.flightId >=. 2000 &&. f.flightId <=. 2025)
  bl <- each bookingLegSchema
  where_ (bl.flightId ==. f.flightId)
  b <- each bookingSchema
  where_ (Rel8Num.fromIntegral bl.bookingId ==. b.bookingId)
  bp <- optional $ do
    bp' <- each boardingPassSchema
    where_ (bp'.bookingLegId ==. nullify (Rel8Num.fromIntegral bl.bookingLegId))
    pure bp'
  pure DeepTreeRow
    { flightId = f.flightId
    , flightNo = f.flightNo
    , scheduledDeparture = f.scheduledDeparture
    , bookingLegId = bl.bookingLegId
    , legNum = bl.legNum
    , bookingId = b.bookingId
    , bookingRef = b.bookingRef
    , passId = (\p -> p.passId) $? bp
    , seat = (\p -> p.seat) $? bp
    }

-- HQ04: Account Relationship Graph with Optional Sub-Entities
hq04AccountRelationshipGraph :: Query (Account Expr)
hq04AccountRelationshipGraph = limit 50 $ do
  a <- each accountSchema
  where_ (a.accountId >=. 1000 &&. a.accountId <=. 1050)
  pure a

-- Helper for raw SQL queries
rawSqlStatement :: ByteString -> Hasql.Statement () ()
rawSqlStatement sql = Hasql.Statement sql Encoders.noParams Decoders.noResult False

executeRaw :: ByteString -> Hasql.Session ()
executeRaw sql = Hasql.statement () (rawSqlStatement sql)

-- HQ05: Fleet & Route Profitability Ledger (5 Tables, 400k+ Rows)
hq05RouteFinancialLedger :: ByteString -> ByteString -> Hasql.Session ()
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
hq06HubCentralityDegree :: ByteString -> ByteString -> Hasql.Session ()
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
hq07AtCapacityLoyaltyCrossCheck :: ByteString -> ByteString -> Hasql.Session ()
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
hq08RecursiveFlightPathSearch :: ByteString -> ByteString -> ByteString -> ByteString -> Hasql.Session ()
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
hq09MultiWindowDelayDispersion :: ByteString -> ByteString -> ByteString -> Hasql.Session ()
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

-- HQ10: Keyset (Cursor) Pagination over Composite Key Under Load
hq10KeysetPagination :: UTCTime -> Int32 -> Int64 -> Query (Flight Expr)
hq10KeysetPagination cursorTime cursorId lim = limit (fromIntegral lim) $
  orderBy (((\f -> f.scheduledDeparture) >$< asc) <> ((\f -> f.flightId) >$< asc)) $ do
    f <- each flightSchema
    where_ (f.scheduledDeparture >. lit cursorTime ||. (f.scheduledDeparture ==. lit cursorTime &&. f.flightId >. lit cursorId))
    pure f

-- HQ11: High-Dimensional Dynamic Faceted Flight Search Engine (10 Optional Predicates)
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

hq11DynamicFacetedSearch :: FlightSearchParams -> Query (Flight Expr, Aircraft Expr)
hq11DynamicFacetedSearch params = limit (fromIntegral params.limitRows) $
  orderBy (((\(f, _) -> f.scheduledDeparture) >$< asc) <> ((\(f, _) -> f.flightId) >$< asc)) $ do
    f <- each flightSchema
    ac <- each aircraftSchema
    where_ (f.aircraftCode ==. ac.code)
    case params.origins of
      Just os -> where_ (in_ f.departureAirport (map lit os))
      Nothing -> pure ()
    case params.destinations of
      Just ds -> where_ (in_ f.arrivalAirport (map lit ds))
      Nothing -> pure ()
    case params.minDeparture of
      Just md -> where_ (f.scheduledDeparture >=. lit md)
      Nothing -> pure ()
    case params.maxDeparture of
      Just xd -> where_ (f.scheduledDeparture <=. lit xd)
      Nothing -> pure ()
    case params.aircraftClasses of
      Just cs -> where_ (in_ ac.class' (map lit cs))
      Nothing -> pure ()
    case params.minRange of
      Just mr -> where_ (ac.range >=. lit mr)
      Nothing -> pure ()
    case params.statuses of
      Just ss -> where_ (in_ f.status (map lit ss))
      Nothing -> pure ()
    case (params.cursorTime, params.cursorId) of
      (Just ct, Just ci) -> where_ (f.scheduledDeparture >. lit ct ||. (f.scheduledDeparture ==. lit ct &&. f.flightId >. lit ci))
      _ -> pure ()
    pure (f, ac)

-- HQ12: High-Volume Batch Upsert (2,500 Records with Conflict Resolution)
hq12BatchUpsert :: Int -> Hasql.Session ()
hq12BatchUpsert count = do
  let rows = [ "(" <> BS8.pack (show i) <> ", 'Departed', clock_timestamp(), clock_timestamp(), clock_timestamp(), 1)" | i <- [1..count] ]
  let sql = "INSERT INTO postgres_air.flight_status_update (flight_id, status, actual_departure, actual_arrival, update_ts, version) " <>
            "VALUES " <> BS8.intercalate ", " rows <> " " <>
            "ON CONFLICT (flight_id) DO UPDATE SET " <>
            "status = EXCLUDED.status, actual_departure = EXCLUDED.actual_departure, " <>
            "actual_arrival = EXCLUDED.actual_arrival, update_ts = EXCLUDED.update_ts, " <>
            "version = postgres_air.flight_status_update.version + 1"
  executeRaw sql

-- HQ13: Optimistic Concurrency Bulk Fare & Status Adjustment
hq13OptimisticBulkUpdate :: Int32 -> Int32 -> Int32 -> Text -> Hasql.Session ()
hq13OptimisticBulkUpdate minFid maxFid expectedVer newStatus = do
  let sql = "UPDATE postgres_air.flight " <>
            "SET status = '" <> BS8.pack (T.unpack newStatus) <> "', version = version + 1, update_ts = clock_timestamp() " <>
            "WHERE flight_id BETWEEN " <> BS8.pack (show minFid) <> " AND " <> BS8.pack (show maxFid) <> " AND version = " <> BS8.pack (show expectedVer)
  executeRaw sql

-- HQ14: High-Concurrency Seat Allocation Under Contention (C=100)
hq14ReserveSeatConcurrent :: Int32 -> Text -> Hasql.Session ()
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
hq15PointsTransferSerializable :: Int32 -> Int32 -> Int32 -> Hasql.Connection -> IO ()
hq15PointsTransferSerializable fromAcc toAcc points conn = go 5
  where
    go 0 = pure ()
    go (attempt :: Int) = do
      res <- Hasql.run session conn
      case res of
        Right () -> pure ()
        Left _ -> do
          threadDelay (10000 * (2 ^ (5 - attempt)))
          go (attempt - 1)
    session = do
      executeRaw "BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE"
      executeRaw $ "UPDATE postgres_air.frequent_flyer SET award_points = award_points - " <> BS8.pack (show points) <> " WHERE frequent_flyer_id = " <> BS8.pack (show fromAcc)
      executeRaw $ "UPDATE postgres_air.frequent_flyer SET award_points = award_points + " <> BS8.pack (show points) <> " WHERE frequent_flyer_id = " <> BS8.pack (show toAcc)
      executeRaw "COMMIT"

-- HQ16: Multi-Modal Hybrid Vector Similarity + BM25 RRF Search
hq16HybridSearchRRF :: ByteString -> ByteString -> Hasql.Session ()
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
