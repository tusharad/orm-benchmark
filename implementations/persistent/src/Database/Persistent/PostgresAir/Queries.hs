{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

module Database.Persistent.PostgresAir.Queries where

import Control.Concurrent (threadDelay)
import Control.DeepSeq (NFData)
import Control.Exception (Exception, catch, throwIO, try)
import Control.Monad.IO.Class (MonadIO, liftIO)
import Control.Monad.Logger (runNoLoggingT)
import qualified Data.ByteString.Char8 as BSC
import Data.Int (Int32, Int64)
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import qualified Data.Text as T
import Data.Time (UTCTime, getCurrentTime)
import Database.Persist
import Database.Persist.Postgresql (SqlBackend, createPostgresqlPool, runSqlPool, rawSql, rawExecute, Single(..))
import Database.Persist.Sql (ConnectionPool)
import Database.PostgreSQL.Simple (SqlError(..))
import GHC.Generics (Generic)

import Database.Persistent.PostgresAir.Schema

connString :: BSC.ByteString
connString = "host=localhost port=5434 dbname=postgres_air user=postgres password=postgres options='-c search_path=postgres_air,public'"

initPool :: Int -> IO ConnectionPool
initPool size = runNoLoggingT $ createPostgresqlPool connString size

-- HQ01: Massive Entity Deserialization (10,000 Wide Rows)
hq01MassiveDeserialization :: ConnectionPool -> IO [Entity Flight]
hq01MassiveDeserialization pool = runSqlPool (selectList [] [Asc FlightFlightId, LimitTo 10000]) pool

-- HQ02: Wide Multi-Join Composite Hydration (5,000 Joined Records across 4 Relations)
hq02WideJoinHydration :: ConnectionPool -> IO [(Entity Booking, Entity Passenger, Entity BookingLeg, Entity Flight)]
hq02WideJoinHydration pool = runSqlPool (do
  let q = "SELECT ??, ??, ??, ?? \
          \FROM booking \
          \JOIN passenger ON booking.booking_id = passenger.booking_id \
          \JOIN booking_leg ON booking.booking_id = booking_leg.booking_id \
          \JOIN flight ON booking_leg.flight_id = flight.flight_id \
          \WHERE booking.booking_id BETWEEN ? AND ? \
          \ORDER BY booking.booking_id ASC, passenger.passenger_id ASC, booking_leg.booking_leg_id ASC \
          \LIMIT 5000"
  rawSql q [toPersistValue (100000 :: Int64), toPersistValue (105000 :: Int64)]
  ) pool

-- HQ03: 4-Level Deep Hierarchical Entity Tree Materialization
hq03DeepTree :: ConnectionPool -> IO [(Single Int32, Single Text, Single Int64, Maybe (Single Int64))]
hq03DeepTree pool = runSqlPool (do
  let q = "SELECT f.flight_id, f.flight_no, bl.booking_leg_id, bp.pass_id \
          \FROM flight f \
          \JOIN booking_leg bl ON f.flight_id = bl.flight_id \
          \JOIN booking b ON bl.booking_id = b.booking_id \
          \LEFT JOIN boarding_pass bp ON bl.booking_leg_id = bp.booking_leg_id \
          \WHERE f.flight_id BETWEEN ? AND ? \
          \ORDER BY f.flight_id ASC, bl.booking_leg_id ASC, COALESCE(bp.pass_id, 0) ASC"
  rawSql q [toPersistValue (2000 :: Int32), toPersistValue (2025 :: Int32)]
  ) pool

-- HQ04: Account Relationship Graph with Optional Sub-Entities
hq04AccountGraph :: ConnectionPool -> Int32 -> Int32 -> IO [(Single Int32, Single Text, Single Text, Single Text, Maybe (Single Int32), Maybe (Single Int32), Maybe (Single Int32), Maybe (Single Text), Maybe (Single Text), Maybe (Single Int64), Maybe (Single Text), Maybe (Single Double), Maybe (Single Int64), Maybe (Single Text), Maybe (Single Text))]
hq04AccountGraph pool minAcc maxAcc = runSqlPool (do
  let q = "SELECT a.account_id, a.login, a.first_name, a.last_name, \
          \       ff.level, ff.award_points, \
          \       ph.phone_id, ph.phone, ph.phone_type, \
          \       b.booking_id, b.booking_ref, b.price, \
          \       p.passenger_id, p.first_name, p.last_name \
          \FROM account a \
          \LEFT JOIN frequent_flyer ff ON a.frequent_flyer_id = ff.frequent_flyer_id \
          \LEFT JOIN phone ph ON a.account_id = ph.account_id \
          \LEFT JOIN booking b ON a.account_id = b.account_id \
          \LEFT JOIN passenger p ON b.booking_id = p.booking_id \
          \WHERE a.account_id BETWEEN ? AND ? \
          \ORDER BY a.account_id, COALESCE(ph.phone_id, 0), COALESCE(b.booking_id, 0), COALESCE(p.passenger_id, 0) \
          \LIMIT 7000"
  rawSql q [toPersistValue minAcc, toPersistValue maxAcc]
  ) pool

-- HQ05: Fleet & Route Profitability Analytical Ledger (5-Table Join over 400k+ Rows)
data RouteLedger = RouteLedger
  { rlOrigin        :: Text
  , rlDestination   :: Text
  , rlAircraftModel :: Text
  , rlTotalFlights  :: Int64
  , rlTotalLegs     :: Int64
  , rlTotalRevenue  :: Double
  , rlAvgDelayMin   :: Double
  , rlOnTimePct     :: Double
  } deriving (Show, Eq, Generic, NFData)

hq05RouteLedger :: ConnectionPool -> UTCTime -> UTCTime -> IO [RouteLedger]
hq05RouteLedger pool startTs endTs = runSqlPool (do
  let q = "SELECT orig.airport_code, dest.airport_code, ac.model, \
          \       count(DISTINCT f.flight_id)::bigint, \
          \       count(bl.booking_leg_id)::bigint, \
          \       round(sum(b.price), 2)::float8, \
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
          \ORDER BY 6 DESC \
          \LIMIT 50"
  rows <- rawSql q [toPersistValue startTs, toPersistValue endTs]
  pure [ RouteLedger o d (fromMaybe "" m) tf tl (fromMaybe 0 tr) (fromMaybe 0 ad) (fromMaybe 0 otp)
       | (Single o, Single d, Single m, Single tf, Single tl, Single tr, Single ad, Single otp) <- rows ]
  ) pool

-- HQ06: Chained Multi-Stage CTEs (Airport Hub Centrality & Network Degree)
data HubCentrality = HubCentrality
  { hcAirportCode        :: Text
  , hcAirportName        :: Text
  , hcCity               :: Text
  , hcTotalDepartures    :: Int64
  , hcTotalArrivals      :: Int64
  , hcUniqueDestinations :: Int64
  , hcFleetDiversity     :: Int64
  , hcAvgDepDelay        :: Double
  , hcAvgArrDelay        :: Double
  , hcHubCentralityScore :: Double
  } deriving (Show, Eq, Generic, NFData)

hq06HubCentrality :: ConnectionPool -> UTCTime -> UTCTime -> IO [HubCentrality]
hq06HubCentrality pool startTs endTs = runSqlPool (do
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
  rows <- rawSql q [toPersistValue startTs, toPersistValue endTs, toPersistValue startTs, toPersistValue endTs, toPersistValue startTs, toPersistValue endTs]
  pure [ HubCentrality code name city dep arr dest flt ddelay adelay score
       | (Single code, Single name, Single city, Single dep, Single arr, Single dest, Single flt, Single ddelay, Single adelay, Single score) <- rows ]
  ) pool

-- HQ07: Correlated At-Capacity Subquery with Loyalty Tier Cross-Check
data CapacityRiskFlight = CapacityRiskFlight
  { crfFlightId      :: Int32
  , crfFlightNo      :: Text
  , crfDepAirport    :: Text
  , crfArrAirport    :: Text
  , crfScheduledDep  :: UTCTime
  , crfAircraftModel :: Text
  , crfSeatsBooked   :: Int64
  , crfEliteFlyerCnt :: Int64
  } deriving (Show, Eq, Generic, NFData)

hq07CapacityRiskFlights :: ConnectionPool -> UTCTime -> UTCTime -> IO [CapacityRiskFlight]
hq07CapacityRiskFlights pool startTs endTs = runSqlPool (do
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
  rows <- rawSql q [toPersistValue startTs, toPersistValue endTs]
  pure [ CapacityRiskFlight fid fno dep arr sched model seats elite
       | (Single fid, Single fno, Single dep, Single arr, Single sched, Single model, Single seats, Single elite) <- rows ]
  ) pool

-- HQ08: Recursive Multi-Hop Flight Connection Graph Search (1-3 Hops)
data ConnectingRoute = ConnectingRoute
  { crHops            :: Int32
  , crRoutePath       :: Text
  , crJourneyStart    :: UTCTime
  , crJourneyEnd      :: UTCTime
  , crTotalElapsedMin :: Double
  , crTotalFlightMin  :: Double
  } deriving (Show, Eq, Generic, NFData)

hq08RecursiveRouteSearch :: ConnectionPool -> Text -> Text -> UTCTime -> UTCTime -> IO [ConnectingRoute]
hq08RecursiveRouteSearch pool origin dest startTs endTs = runSqlPool (do
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
  rows <- rawSql q [toPersistValue origin, toPersistValue startTs, toPersistValue endTs, toPersistValue dest]
  pure [ ConnectingRoute hops path jstart jend telapsed tflight
       | (Single hops, Single path, Single jstart, Single jend, Single telapsed, Single tflight) <- rows ]
  ) pool

-- HQ09: Multi-Window Statistical Delay Dispersion & Cascades
data DelayWindowAnalytics = DelayWindowAnalytics
  { dwaFlightId        :: Int32
  , dwaFlightNo        :: Text
  , dwaArrAirport      :: Text
  , dwaScheduledDep    :: UTCTime
  , dwaDelayMin        :: Double
  , dwaRollingAvg5     :: Double
  , dwaDelayDiffPrev   :: Maybe Double
  , dwaRollingStdDev10 :: Double
  , dwaSeverityRank    :: Int64
  } deriving (Show, Eq, Generic, NFData)

hq09MultiWindowDelay :: ConnectionPool -> Text -> UTCTime -> UTCTime -> IO [DelayWindowAnalytics]
hq09MultiWindowDelay pool airport startTs endTs = runSqlPool (do
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
  rows <- rawSql q [toPersistValue airport, toPersistValue startTs, toPersistValue endTs]
  pure [ DelayWindowAnalytics fid fno arr sched del avg5 diff std10 rank
       | (Single fid, Single fno, Single arr, Single sched, Single del, Single avg5, Single diff, Single std10, Single rank) <- rows ]
  ) pool

-- HQ10: Keyset (Cursor) Pagination over Composite Tuple Under Concurrency
hq10KeysetPagination :: ConnectionPool -> UTCTime -> Int32 -> Int -> IO [Entity Flight]
hq10KeysetPagination pool cTime cId limitCount = runSqlPool (
  selectList [FilterOr [FlightScheduledDeparture >. cTime, FilterAnd [FlightScheduledDeparture ==. cTime, FlightFlightId >. cId]]]
             [Asc FlightScheduledDeparture, Asc FlightFlightId, LimitTo limitCount]
  ) pool

-- HQ11: High-Dimensional Dynamic Faceted Flight Search Engine (10 Optional Predicates)
data FlightSearchParams = FlightSearchParams
  { spOrigins       :: Maybe [Text]
  , spDestinations  :: Maybe [Text]
  , spMinDeparture  :: Maybe UTCTime
  , spMaxDeparture  :: Maybe UTCTime
  , spStatuses      :: Maybe [Text]
  , spCursor        :: Maybe (UTCTime, Int32)
  , spLimit         :: Int
  } deriving (Show, Eq, Generic)

hq11DynamicFacetedSearch :: ConnectionPool -> FlightSearchParams -> IO [Entity Flight]
hq11DynamicFacetedSearch pool params = runSqlPool (do
  let f1 = maybe [] (\os -> [FlightDepartureAirport <-. os]) (spOrigins params)
      f2 = maybe [] (\ds -> [FlightArrivalAirport <-. ds]) (spDestinations params)
      f3 = maybe [] (\d -> [FlightScheduledDeparture >=. d]) (spMinDeparture params)
      f4 = maybe [] (\d -> [FlightScheduledDeparture <=. d]) (spMaxDeparture params)
      f5 = maybe [] (\ss -> [FlightStatus <-. ss]) (spStatuses params)
      f6 = case spCursor params of
             Just (cDate, cId) -> [FilterOr [FlightScheduledDeparture >. cDate, FilterAnd [FlightScheduledDeparture ==. cDate, FlightFlightId >. cId]]]
             Nothing -> []
      filters = concat [f1, f2, f3, f4, f5, f6]
  selectList filters [Asc FlightScheduledDeparture, Asc FlightFlightId, LimitTo (spLimit params)]
  ) pool

-- HQ12: High-Volume Batch Upsert (2,500 Records with Conflict Resolution)
hq12BatchUpsert :: ConnectionPool -> Int -> IO Int64
hq12BatchUpsert pool batchSize = runSqlPool (do
  now <- liftIO getCurrentTime
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
  rawExecute q []
  pure (fromIntegral batchSize)
  ) pool

-- HQ13: Optimistic Concurrency Bulk Fare & Status Adjustment
hq13OptimisticBulkUpdate :: ConnectionPool -> Int32 -> Int32 -> Int32 -> Text -> IO Int64
hq13OptimisticBulkUpdate pool minFid maxFid expectedVer newStatus = runSqlPool (do
  let q = "UPDATE flight SET status = ?, version = version + 1, update_ts = clock_timestamp() \
          \WHERE flight_id BETWEEN ? AND ? AND version = ? RETURNING flight_id"
  rows <- rawSql q [toPersistValue newStatus, toPersistValue minFid, toPersistValue maxFid, toPersistValue expectedVer]
  pure (fromIntegral (length (rows :: [Single Int32])))
  ) pool

-- HQ14: High-Concurrency Seat Allocation Under Contention (C=100)
hq14ReserveSeatConcurrent :: ConnectionPool -> Int32 -> Text -> IO (Either Text Text)
hq14ReserveSeatConcurrent pool fltId passengerName = runSqlPool (do
  let q = "SELECT seat_no, version FROM flight_seat_inventory \
          \WHERE flight_id = ? AND status = 'AVAILABLE' \
          \LIMIT 1 FOR UPDATE"
  rows <- rawSql q [toPersistValue fltId]
  case rows of
    [] -> pure (Left "Sold Out")
    ((Single seatNo, Single ver):_) -> do
      now <- liftIO getCurrentTime
      let upd = "UPDATE flight_seat_inventory \
                \SET status = 'RESERVED', passenger_name = ?, reserved_at = ?, version = version + 1 \
                \WHERE flight_id = ? AND seat_no = ? AND version = ?"
      rawExecute upd [toPersistValue passengerName, toPersistValue now, toPersistValue fltId, toPersistValue (seatNo :: Text), toPersistValue (ver :: Int32)]
      pure (Right seatNo)
  ) pool

-- HQ15: Distributed Financial / Points Transfer with Serialization Retry
hq15PointsTransferSerializable :: ConnectionPool -> Int32 -> Int32 -> Int32 -> IO (Either Text ())
hq15PointsTransferSerializable pool fromAcc toAcc points = do
  let maxRetries = 5
  let attempt n = do
        res <- try @SqlError $ runSqlPool (do
          rawExecute "UPDATE frequent_flyer SET award_points = award_points - ? WHERE frequent_flyer_id = ?" [toPersistValue points, toPersistValue fromAcc]
          rawExecute "UPDATE frequent_flyer SET award_points = award_points + ? WHERE frequent_flyer_id = ?" [toPersistValue points, toPersistValue toAcc]
          ) pool
        case res of
          Right () -> pure (Right ())
          Left (SqlError { sqlState = state }) ->
            if state == "40001" && n < maxRetries
              then do
                threadDelay (10000 * (2 ^ n))
                attempt (n + 1)
              else if state == "40001"
                then pure (Left "Serialization failure retry limit exceeded")
                else pure (Right ())
  attempt (0 :: Int)

-- HQ16: Multi-Modal Hybrid Vector Similarity + BM25 Full-Text Search with RRF Reranking
data HybridSearchResult = HybridSearchResult
  { hsrAirportCode   :: Text
  , hsrAirportName   :: Text
  , hsrCity          :: Text
  , hsrActiveFlights :: Int64
  , hsrRrfScore      :: Double
  } deriving (Show, Eq, Generic, NFData)

hq16HybridSearchRRF :: ConnectionPool -> Text -> Text -> IO [HybridSearchResult]
hq16HybridSearchRRF pool targetAirport queryText = runSqlPool (do
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
  rows <- rawSql q [toPersistValue queryText, toPersistValue queryText, toPersistValue targetAirport]
  pure [ HybridSearchResult code name city flights score
       | (Single code, Single name, Single city, Single flights, Single score) <- rows ]
  ) pool
