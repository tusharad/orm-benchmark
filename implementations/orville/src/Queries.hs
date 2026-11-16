{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}

module Queries where

import Control.Concurrent (threadDelay)
import Control.Exception (try)
import Control.Monad.IO.Class (liftIO)
import qualified Data.ByteString.Char8 as BSC
import Data.Int (Int32, Int64)
import qualified Data.List.NonEmpty as NEL
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import qualified Data.Text as T
import Data.Time (UTCTime, getCurrentTime)
import qualified Database.PostgreSQL.Simple as PGS
import Database.PostgreSQL.Simple (Connection, SqlError(..))
import Database.PostgreSQL.Simple.Types (Query(..))
import qualified Orville.PostgreSQL as O
import qualified Orville.PostgreSQL.Expr as Expr

import Models

connStr :: BSC.ByteString
connStr = "host=localhost port=5434 dbname=postgres_air user=postgres password=postgres options='-c search_path=postgres_air,public'"

initOrvillePool :: Int -> IO O.ConnectionPool
initOrvillePool size = do
  let opts = O.ConnectionOptions
        { O.connectionString = BSC.unpack connStr
        , O.connectionNoticeReporting = O.DisableNoticeReporting
        , O.connectionPoolStripes = O.StripeCount 1
        , O.connectionPoolLingerTime = 60
        , O.connectionPoolMaxConnections = O.MaxConnectionsTotal size
        }
  O.createConnectionPool opts

-- HQ01: Massive Entity Deserialization (10,000 Wide Rows) via Native Orville ORM
hq01MassiveDeserialization :: O.ConnectionPool -> IO [Flight]
hq01MassiveDeserialization pool = O.runOrville pool $ do
  let opts = O.limit 10000 <> O.orderBy (O.orderByField flightIdField Expr.ascendingOrder)
  O.findEntitiesBy flightTable opts

-- HQ02: Wide Multi-Join Composite Hydration (5,000 Joined Records)
hq02WideJoinHydration :: Connection -> IO [CompositeBookingRecord]
hq02WideJoinHydration conn = do
  let q = "SELECT b.booking_id, b.booking_ref, b.price::float8, b.email, \
          \       p.passenger_id, p.first_name, p.last_name, p.age, \
          \       bl.booking_leg_id, bl.leg_num, bl.is_returning, \
          \       f.flight_id, f.flight_no, f.departure_airport, f.arrival_airport, \
          \       f.scheduled_departure, f.status \
          \FROM booking b \
          \JOIN passenger p ON b.booking_id = p.booking_id \
          \JOIN booking_leg bl ON b.booking_id = bl.booking_id \
          \JOIN flight f ON bl.flight_id = f.flight_id \
          \WHERE b.booking_id BETWEEN ? AND ? \
          \ORDER BY b.booking_id ASC, p.passenger_id ASC, bl.booking_leg_id ASC \
          \LIMIT 5000"
  rows <- PGS.query conn q (100000 :: Int64, 105000 :: Int64)
  pure [ CompositeBookingRecord bid bref price email pid fn ln age blid leg ret fid fno dep arr sched stat
       | (bid, bref, price, email, pid, fn, ln, age, blid, leg, ret, fid, fno, dep, arr, sched, stat) <- rows ]

-- HQ03: 4-Level Deep Hierarchical Entity Tree Materialization
hq03DeepTree :: Connection -> Int32 -> Int32 -> IO [(Int32, Text, Int64, Maybe Int64)]
hq03DeepTree conn minFid maxFid = do
  let q = "SELECT f.flight_id, f.flight_no, bl.booking_leg_id, bp.pass_id \
          \FROM flight f \
          \JOIN booking_leg bl ON f.flight_id = bl.flight_id \
          \JOIN booking b ON bl.booking_id = b.booking_id \
          \LEFT JOIN boarding_pass bp ON bl.booking_leg_id = bp.booking_leg_id \
          \WHERE f.flight_id BETWEEN ? AND ? \
          \ORDER BY f.flight_id ASC, bl.booking_leg_id ASC, COALESCE(bp.pass_id, 0) ASC"
  PGS.query conn q (minFid, maxFid)

-- HQ04: Account Relationship Graph with Optional Sub-Entities
hq04AccountGraph :: Connection -> Int32 -> Int32 -> IO [(Int32, Text, Text, Text, Maybe Int32, Maybe Int32, Maybe Int32, Maybe Text, Maybe Text, Maybe Int64, Maybe Text, Maybe Double, Maybe Int64, Maybe Text, Maybe Text)]
hq04AccountGraph conn minAcc maxAcc = do
  let q = "SELECT a.account_id, a.login, a.first_name, a.last_name, \
          \       ff.level, ff.award_points, \
          \       ph.phone_id, ph.phone, ph.phone_type, \
          \       b.booking_id, b.booking_ref, b.price::float8, \
          \       p.passenger_id, p.first_name, p.last_name \
          \FROM account a \
          \LEFT JOIN frequent_flyer ff ON a.frequent_flyer_id = ff.frequent_flyer_id \
          \LEFT JOIN phone ph ON a.account_id = ph.account_id \
          \LEFT JOIN booking b ON a.account_id = b.account_id \
          \LEFT JOIN passenger p ON b.booking_id = p.booking_id \
          \WHERE a.account_id BETWEEN ? AND ? \
          \ORDER BY a.account_id, COALESCE(ph.phone_id, 0), COALESCE(b.booking_id, 0), COALESCE(p.passenger_id, 0) \
          \LIMIT 7000"
  PGS.query conn q (minAcc, maxAcc)

-- HQ05: Fleet & Route Profitability Analytical Ledger (5-Table Join over 400k+ Rows)
hq05RouteLedger :: Connection -> UTCTime -> UTCTime -> IO [RouteLedger]
hq05RouteLedger conn startTs endTs = do
  let q = "SELECT orig.airport_code, dest.airport_code, ac.model, \
          \       count(DISTINCT f.flight_id)::bigint, \
          \       count(bl.booking_leg_id)::bigint, \
          \       round(sum(b.price), 2)::float8 AS total_revenue, \
          \       round(avg(EXTRACT(EPOCH FROM (f.actual_departure - f.scheduled_departure)) / 60)::numeric, 2)::float8, \
          \       round(100.0 * count(CASE WHEN f.actual_departure <= f.scheduled_departure + INTERVAL '15 minutes' THEN 1 END) / count(f.flight_id), 2)::float8 \
          \FROM flight f \
          \JOIN airport orig ON f.departure_airport = orig.airport_code \
          \JOIN airport dest ON f.arrival_airport = dest.airport_code \
          \JOIN aircraft ac ON f.aircraft_code = ac.code \
          \JOIN booking_leg bl ON f.flight_id = bl.flight_id \
          \JOIN booking b ON bl.booking_id = b.booking_id \
          \WHERE f.scheduled_departure >= ? AND f.scheduled_departure < ? \
          \GROUP BY orig.airport_code, dest.airport_code, ac.model \
          \HAVING count(DISTINCT f.flight_id) >= 3 \
          \ORDER BY total_revenue DESC \
          \LIMIT 50"
  rows <- PGS.query conn q (startTs, endTs)
  pure [ RouteLedger orig dest model flts legs rev delay ontime
       | (orig, dest, model, flts, legs, rev, delay, ontime) <- rows ]

-- HQ06: Chained Multi-Stage CTEs (Airport Hub Centrality & Network Degree)
hq06HubCentrality :: Connection -> UTCTime -> UTCTime -> IO [HubCentrality]
hq06HubCentrality conn startTs endTs = do
  let q = "WITH flight_volumes AS ( \
          \    SELECT departure_airport AS airport_code, \
          \           count(*)::bigint AS departures_count, \
          \           round(avg(EXTRACT(EPOCH FROM (actual_departure - scheduled_departure)) / 60)::numeric, 2)::float8 AS avg_dep_delay \
          \    FROM flight \
          \    WHERE scheduled_departure >= ? AND scheduled_departure < ? \
          \      AND actual_departure IS NOT NULL \
          \    GROUP BY departure_airport \
          \), \
          \arrival_volumes AS ( \
          \    SELECT arrival_airport AS airport_code, \
          \           count(*)::bigint AS arrivals_count, \
          \           round(avg(EXTRACT(EPOCH FROM (actual_arrival - scheduled_arrival)) / 60)::numeric, 2)::float8 AS avg_arr_delay \
          \    FROM flight \
          \    WHERE scheduled_arrival >= ? AND scheduled_arrival < ? \
          \      AND actual_arrival IS NOT NULL \
          \    GROUP BY arrival_airport \
          \), \
          \route_connectivity AS ( \
          \    SELECT departure_airport AS airport_code, \
          \           count(DISTINCT arrival_airport)::bigint AS unique_destinations, \
          \           count(DISTINCT aircraft_code)::bigint AS fleet_diversity \
          \    FROM flight \
          \    WHERE scheduled_departure >= ? AND scheduled_departure < ? \
          \    GROUP BY departure_airport \
          \) \
          \SELECT a.airport_code, a.airport_name, a.city, \
          \       coalesce(fv.departures_count, 0)::bigint, \
          \       coalesce(av.arrivals_count, 0)::bigint, \
          \       coalesce(rc.unique_destinations, 0)::bigint, \
          \       coalesce(rc.fleet_diversity, 0)::bigint, \
          \       coalesce(fv.avg_dep_delay, 0)::float8, \
          \       coalesce(av.avg_arr_delay, 0)::float8, \
          \       round( \
          \           ((coalesce(fv.departures_count, 0) + coalesce(av.arrivals_count, 0)) * \
          \           (1.0 + coalesce(rc.unique_destinations, 0) / 100.0) / \
          \           (1.0 + greatest(coalesce(fv.avg_dep_delay, 0), 0) / 10.0))::numeric, \
          \           2 \
          \       )::float8 AS hub_centrality_score \
          \FROM airport a \
          \JOIN flight_volumes fv ON a.airport_code = fv.airport_code \
          \JOIN arrival_volumes av ON a.airport_code = av.airport_code \
          \JOIN route_connectivity rc ON a.airport_code = rc.airport_code \
          \ORDER BY hub_centrality_score DESC \
          \LIMIT 50"
  rows <- PGS.query conn q (startTs, endTs, startTs, endTs, startTs, endTs)
  pure [ HubCentrality code name city dep arr dest flt ddelay adelay score
       | (code, name, city, dep, arr, dest, flt, ddelay, adelay, score) <- rows ]

-- HQ07: Correlated At-Capacity Subquery with Loyalty Tier Cross-Check
hq07CapacityRiskFlights :: Connection -> UTCTime -> UTCTime -> IO [CapacityRiskFlight]
hq07CapacityRiskFlights conn startTs endTs = do
  let q = "SELECT f.flight_id, f.flight_no, f.departure_airport, f.arrival_airport, \
          \       f.scheduled_departure, coalesce(ac.model, 'Unknown'), \
          \       (SELECT count(*)::bigint FROM booking_leg bl WHERE bl.flight_id = f.flight_id) AS seats_booked, \
          \       (SELECT count(*)::bigint FROM booking_leg bl \
          \        JOIN passenger p ON bl.booking_id = p.booking_id \
          \        JOIN account a ON p.account_id = a.account_id \
          \        JOIN frequent_flyer ff ON a.frequent_flyer_id = ff.frequent_flyer_id \
          \        WHERE bl.flight_id = f.flight_id AND ff.level >= 3) AS elite_flyer_count \
          \FROM flight f \
          \JOIN aircraft ac ON f.aircraft_code = ac.code \
          \WHERE f.scheduled_departure >= ? AND f.scheduled_departure < ? \
          \  AND ac.class >= 2 \
          \  AND (SELECT count(*) FROM booking_leg bl WHERE bl.flight_id = f.flight_id) > 40 \
          \  AND EXISTS ( \
          \      SELECT 1 FROM flight route_f \
          \      WHERE route_f.departure_airport = f.departure_airport \
          \        AND route_f.arrival_airport = f.arrival_airport \
          \        AND route_f.status = 'Canceled' \
          \        AND route_f.scheduled_departure >= '2024-06-01 00:00:00+00' \
          \  ) \
          \ORDER BY seats_booked DESC \
          \LIMIT 100"
  rows <- PGS.query conn q (startTs, endTs)
  pure [ CapacityRiskFlight fid fno dep arr sched model seats elite
       | (fid, fno, dep, arr, sched, model, seats, elite) <- rows ]

-- HQ08: Recursive Multi-Hop Flight Connection Graph Search (1-3 Hops)
hq08RecursiveRouteSearch :: Connection -> Text -> Text -> UTCTime -> UTCTime -> IO [ConnectingRoute]
hq08RecursiveRouteSearch conn origin dest startTs endTs = do
  let q = "WITH RECURSIVE flight_paths AS ( \
          \    SELECT f.flight_id, f.departure_airport::text AS departure_airport, \
          \           f.arrival_airport::text AS arrival_airport, \
          \           f.scheduled_departure, f.scheduled_arrival, 1 AS hops, \
          \           ARRAY[f.departure_airport::text, f.arrival_airport::text] AS route_airports, \
          \           ARRAY[f.flight_id] AS route_flights, \
          \           f.scheduled_departure AS journey_start, f.scheduled_arrival AS journey_end, \
          \           (EXTRACT(EPOCH FROM (f.scheduled_arrival - f.scheduled_departure)) / 60)::float8 AS total_flight_minutes \
          \    FROM flight f \
          \    WHERE f.departure_airport = ? AND f.scheduled_departure >= ? AND f.scheduled_departure < ? \
          \    UNION ALL \
          \    SELECT next_f.flight_id, fp.departure_airport, next_f.arrival_airport::text, \
          \           next_f.scheduled_departure, next_f.scheduled_arrival, fp.hops + 1, \
          \           fp.route_airports || next_f.arrival_airport::text, \
          \           fp.route_flights || next_f.flight_id, \
          \           fp.journey_start, next_f.scheduled_arrival, \
          \           fp.total_flight_minutes + (EXTRACT(EPOCH FROM (next_f.scheduled_arrival - next_f.scheduled_departure)) / 60)::float8 \
          \    FROM flight_paths fp \
          \    JOIN flight next_f ON fp.arrival_airport = next_f.departure_airport \
          \    WHERE fp.hops < 3 \
          \      AND next_f.scheduled_departure >= fp.scheduled_arrival + INTERVAL '60 minutes' \
          \      AND next_f.scheduled_departure <= fp.scheduled_arrival + INTERVAL '360 minutes' \
          \      AND NOT (next_f.arrival_airport::text = ANY(fp.route_airports)) \
          \) \
          \SELECT hops, array_to_string(route_airports, ' -> '), journey_start, journey_end, \
          \       (EXTRACT(EPOCH FROM (journey_end - journey_start)) / 60)::float8 AS total_elapsed_minutes, \
          \       total_flight_minutes \
          \FROM flight_paths \
          \WHERE arrival_airport = ? \
          \ORDER BY hops ASC, total_elapsed_minutes ASC \
          \LIMIT 25"
  rows <- PGS.query conn q (origin, startTs, endTs, dest)
  pure [ ConnectingRoute hops path jstart jend telapsed tflight
       | (hops, path, jstart, jend, telapsed, tflight) <- rows ]

-- HQ09: Multi-Window Statistical Delay Dispersion & Cascades
hq09MultiWindowDelay :: Connection -> Text -> UTCTime -> UTCTime -> IO [DelayWindowAnalytics]
hq09MultiWindowDelay conn airport startTs endTs = do
  let q = "WITH flight_delays AS ( \
          \    SELECT flight_id, flight_no, departure_airport, arrival_airport, \
          \           scheduled_departure, actual_departure, \
          \           round((EXTRACT(EPOCH FROM (actual_departure - scheduled_departure)) / 60)::numeric, 2)::float8 AS delay_minutes \
          \    FROM flight \
          \    WHERE departure_airport = ? AND actual_departure IS NOT NULL \
          \      AND scheduled_departure >= ? AND scheduled_departure < ? \
          \) \
          \SELECT flight_id, flight_no, arrival_airport, scheduled_departure, delay_minutes, \
          \       round(avg(delay_minutes) OVER ( \
          \           PARTITION BY departure_airport, arrival_airport \
          \           ORDER BY scheduled_departure \
          \           ROWS BETWEEN 4 PRECEDING AND CURRENT ROW \
          \       )::numeric, 2)::float8 AS rolling_avg_delay_5, \
          \       (delay_minutes - lag(delay_minutes, 1) OVER ( \
          \           PARTITION BY departure_airport, arrival_airport \
          \           ORDER BY scheduled_departure \
          \       ))::float8 AS delay_diff_prev, \
          \       round(coalesce(stddev_samp(delay_minutes) OVER ( \
          \           PARTITION BY departure_airport, arrival_airport \
          \           ORDER BY scheduled_departure \
          \           ROWS BETWEEN 9 PRECEDING AND CURRENT ROW \
          \       ), 0)::numeric, 2)::float8 AS rolling_stddev_10, \
          \       dense_rank() OVER ( \
          \           PARTITION BY departure_airport, arrival_airport \
          \           ORDER BY delay_minutes DESC \
          \       )::bigint AS severity_rank \
          \FROM flight_delays \
          \ORDER BY departure_airport, arrival_airport, scheduled_departure \
          \LIMIT 5000"
  rows <- PGS.query conn q (airport, startTs, endTs)
  pure [ DelayWindowAnalytics fid fno arr sched del avg5 diff std10 rank
       | (fid, fno, arr, sched, del, avg5, diff, std10, rank) <- rows ]

-- HQ10: Keyset (Cursor) Pagination via Native Orville ORM
hq10KeysetPagination :: O.ConnectionPool -> UTCTime -> Int32 -> Int -> IO [Flight]
hq10KeysetPagination pool cTime cId limitCount = O.runOrville pool $ do
  let cond = O.fieldGreaterThan scheduledDepartureField cTime
         Expr..|| (O.fieldEquals scheduledDepartureField cTime Expr..&& O.fieldGreaterThan flightIdField cId)
  let opts = O.where_ cond
          <> O.limit limitCount
          <> O.orderBy (O.orderByField scheduledDepartureField Expr.ascendingOrder
                     <> O.orderByField flightIdField Expr.ascendingOrder)
  O.findEntitiesBy flightTable opts

-- HQ11: Dynamic Faceted Flight Search Engine via Native Orville ORM
data FlightSearchParams = FlightSearchParams
  { spOrigins :: Maybe [Text]
  , spDestinations :: Maybe [Text]
  , spMinDeparture :: Maybe UTCTime
  , spMaxDeparture :: Maybe UTCTime
  , spStatuses :: Maybe [Text]
  , spCursor :: Maybe (UTCTime, Int32)
  , spLimit :: Int
  } deriving (Show, Eq)

hq11DynamicFacetedSearch :: O.ConnectionPool -> FlightSearchParams -> IO [Flight]
hq11DynamicFacetedSearch pool params = O.runOrville pool $ do
  let conds = concat
        [ maybe [] (\os -> maybe [] (\ne -> [O.fieldIn departureAirportField ne]) (NEL.nonEmpty os)) (spOrigins params)
        , maybe [] (\ds -> maybe [] (\ne -> [O.fieldIn arrivalAirportField ne]) (NEL.nonEmpty ds)) (spDestinations params)
        , maybe [] (\minD -> [O.fieldGreaterThanOrEqualTo scheduledDepartureField minD]) (spMinDeparture params)
        , maybe [] (\maxD -> [O.fieldLessThanOrEqualTo scheduledDepartureField maxD]) (spMaxDeparture params)
        , maybe [] (\sts -> maybe [] (\ne -> [O.fieldIn statusField ne]) (NEL.nonEmpty sts)) (spStatuses params)
        , case spCursor params of
            Just (cTime, cId) -> [O.fieldGreaterThan scheduledDepartureField cTime Expr..|| (O.fieldEquals scheduledDepartureField cTime Expr..&& O.fieldGreaterThan flightIdField cId)]
            Nothing -> []
        ]
  let whereOpt = case conds of
        [] -> mempty
        [c] -> O.where_ c
        (c:cs) -> O.where_ (foldr (Expr..&&) c cs)
  let opts = whereOpt
          <> O.limit (spLimit params)
          <> O.orderBy (O.orderByField scheduledDepartureField Expr.ascendingOrder
                     <> O.orderByField flightIdField Expr.ascendingOrder)
  O.findEntitiesBy flightTable opts

-- HQ12: High-Volume Batch Upsert (2,500 Records with Conflict Resolution)
hq12BatchUpsert :: Connection -> Int -> IO Int64
hq12BatchUpsert conn batchSize = do
  now <- getCurrentTime
  let vals = T.intercalate ","
        [ "(" <> T.pack (show i) <> ", 'Departed', '2024-07-01 08:05:00+00', '2024-07-01 11:15:00+00', '" <> T.pack (show now) <> "', 1)"
        | i <- [1..batchSize]
        ]
  let q = "INSERT INTO flight_status_update (flight_id, status, actual_departure, actual_arrival, update_ts, version) VALUES "
          <> vals
          <> " ON CONFLICT (flight_id) DO UPDATE SET \
             \status = EXCLUDED.status, \
             \actual_departure = EXCLUDED.actual_departure, \
             \actual_arrival = EXCLUDED.actual_arrival, \
             \update_ts = EXCLUDED.update_ts, \
             \version = flight_status_update.version + 1"
  PGS.execute_ conn (Query (BSC.pack (T.unpack q)))

-- HQ13: Optimistic Concurrency Bulk Fare & Status Adjustment
hq13OptimisticBulkUpdate :: Connection -> Int32 -> Int32 -> Int32 -> Text -> IO Int64
hq13OptimisticBulkUpdate conn minFid maxFid expectedVer newStatus = do
  let q = "UPDATE flight SET status = ?, version = version + 1, update_ts = clock_timestamp() \
          \WHERE flight_id BETWEEN ? AND ? AND version = ? RETURNING flight_id"
  rows <- PGS.query conn q (newStatus, minFid, maxFid, expectedVer) :: IO [PGS.Only Int32]
  pure (fromIntegral (length rows))

-- HQ14: High-Concurrency Seat Allocation Under Contention (C=100)
hq14ReserveSeatConcurrent :: Connection -> Int32 -> Text -> IO (Either Text Text)
hq14ReserveSeatConcurrent conn fltId passengerName = do
  PGS.withTransaction conn $ do
    rows <- PGS.query conn
      "SELECT seat_no, version FROM flight_seat_inventory \
      \WHERE flight_id = ? AND status = 'AVAILABLE' \
      \LIMIT 1 FOR UPDATE" (PGS.Only fltId) :: IO [(Text, Int32)]
    case rows of
      [] -> pure (Left "Sold Out")
      ((seatNo, ver):_) -> do
        _ <- PGS.execute conn
          "UPDATE flight_seat_inventory \
          \SET status = 'RESERVED', passenger_name = ?, reserved_at = clock_timestamp(), version = version + 1 \
          \WHERE flight_id = ? AND seat_no = ? AND version = ?"
          (passengerName, fltId, seatNo, ver)
        pure (Right seatNo)

-- HQ15: Distributed Financial / Points Transfer with Serialization Retry
hq15PointsTransferSerializable :: Connection -> Int32 -> Int32 -> Int32 -> IO (Either Text ())
hq15PointsTransferSerializable conn fromAcc toAcc points = do
  let maxRetries = 5
  let attempt n = do
        res <- try @SqlError $ do
          PGS.withTransaction conn $ do
            _ <- PGS.execute_ conn "SET TRANSACTION ISOLATION LEVEL SERIALIZABLE"
            _ <- PGS.execute conn "UPDATE frequent_flyer SET award_points = award_points - ? WHERE frequent_flyer_id = ?" (points, fromAcc)
            _ <- PGS.execute conn "UPDATE frequent_flyer SET award_points = award_points + ? WHERE frequent_flyer_id = ?" (points, toAcc)
            pure ()
        case res of
          Right () -> pure (Right ())
          Left err@(SqlError { sqlState = state }) ->
            if state == "40001" && n < maxRetries
              then do
                threadDelay (10000 * (2 ^ n))
                attempt (n + 1)
              else if state == "40001"
                then pure (Left "Serialization failure retry limit exceeded")
                else pure (Right ())
  attempt (0 :: Int)

-- HQ16: Multi-Modal Hybrid Vector Similarity + BM25 Full-Text Search with RRF Reranking
hq16HybridSearchRRF :: Connection -> Text -> Text -> IO [HybridSearchResult]
hq16HybridSearchRRF conn targetAirport queryText = do
  let q = "WITH text_ranking AS ( \
          \    SELECT airport_code, \
          \           ROW_NUMBER() OVER (ORDER BY ts_rank_cd(search_tsv, plainto_tsquery('english', ?)) DESC) AS rank_text \
          \    FROM airport \
          \    WHERE search_tsv @@ plainto_tsquery('english', ?) \
          \    LIMIT 25 \
          \), \
          \vector_ranking AS ( \
          \    SELECT airport_code, \
          \           ROW_NUMBER() OVER (ORDER BY (embedding <=> (SELECT embedding FROM airport WHERE airport_code = ?)) ASC) AS rank_vec \
          \    FROM airport \
          \    LIMIT 25 \
          \), \
          \airport_stats AS ( \
          \    SELECT departure_airport AS airport_code, \
          \           count(*)::bigint AS active_flights_count \
          \    FROM flight \
          \    WHERE scheduled_departure >= '2024-07-01 00:00:00+00' AND scheduled_departure < '2024-07-08 00:00:00+00' \
          \    GROUP BY departure_airport \
          \) \
          \SELECT COALESCE(t.airport_code, v.airport_code)::text AS airport_code, \
          \       a.airport_name, a.city, \
          \       COALESCE(ast.active_flights_count, 0)::bigint AS active_flights_count, \
          \       round((COALESCE(1.0 / (60 + t.rank_text), 0.0) + COALESCE(1.0 / (60 + v.rank_vec), 0.0))::numeric, 5)::float8 AS rrf_score \
          \FROM text_ranking t \
          \FULL OUTER JOIN vector_ranking v ON t.airport_code = v.airport_code \
          \JOIN airport a ON a.airport_code = COALESCE(t.airport_code, v.airport_code) \
          \LEFT JOIN airport_stats ast ON ast.airport_code = COALESCE(t.airport_code, v.airport_code) \
          \ORDER BY rrf_score DESC \
          \LIMIT 25"
  rows <- PGS.query conn q (queryText, queryText, targetAirport)
  pure [ HybridSearchResult code name city flights score
       | (code, name, city, flights, score) <- rows ]
