{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

module Database.Esqueleto.PostgresAir.Queries where

import Control.Concurrent (threadDelay)
import Control.Exception (Exception, catch, throwIO, try)
import Control.Monad.IO.Class (MonadIO, liftIO)
import Control.Monad.Logger (runNoLoggingT)
import qualified Data.ByteString.Char8 as BSC
import Data.Int (Int32, Int64)
import qualified Data.Map.Strict as Map
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import qualified Data.Text as T
import Data.Time (UTCTime, getCurrentTime)
import Database.Esqueleto.Experimental
import qualified Database.Esqueleto.PostgreSQL as Pg
import Database.Persist.Postgresql (SqlBackend, createPostgresqlPool, runSqlPool, rawSql, rawExecute, Single(..))
import Database.Persist.Sql (ConnectionPool)
import Database.PostgreSQL.Simple (SqlError(..))
import GHC.Generics (Generic)

import Database.Esqueleto.PostgresAir.Schema

connString :: BSC.ByteString
connString = "host=localhost port=5434 dbname=postgres_air user=postgres password=postgres options='-c search_path=postgres_air,public'"

initPool :: Int -> IO ConnectionPool
initPool size = runNoLoggingT $ createPostgresqlPool connString size

-- =========================================================================
-- Category I: Large-Scale Hydration, Memory & Deserialization Strain
-- =========================================================================

-- HQ01: Massive Entity Deserialization (10,000 Wide Rows)
hq01MassiveDeserialization :: ConnectionPool -> IO [Entity Flight]
hq01MassiveDeserialization pool = runSqlPool (select $ do
    f <- from $ table @Flight
    orderBy [asc (f ^. FlightFlightId)]
    limit 10000
    pure f) pool

-- HQ02: Wide Multi-Join Composite Hydration (5,000 Joined Records across 4 Relations)
hq02WideJoinHydration :: ConnectionPool -> IO [(Entity Booking, Entity Passenger, Entity BookingLeg, Entity Flight)]
hq02WideJoinHydration pool = runSqlPool (select $ do
    (b :& p :& bl :& f) <- from $
        table @Booking
        `innerJoin` table @Passenger
            `on` (\(b :& p) -> b ^. BookingBookingId ==. p ^. PassengerBookingId)
        `innerJoin` table @BookingLeg
            `on` (\(b :& _ :& bl) -> b ^. BookingBookingId ==. bl ^. BookingLegBookingId)
        `innerJoin` table @Flight
            `on` (\(_ :& _ :& bl :& f) -> bl ^. BookingLegFlightId ==. f ^. FlightFlightId)
    where_ (b ^. BookingBookingId >=. val 100000 &&. b ^. BookingBookingId <=. val 105000)
    orderBy [asc (b ^. BookingBookingId), asc (p ^. PassengerPassengerId), asc (bl ^. BookingLegBookingLegId)]
    limit 5000
    pure (b, p, bl, f)) pool

-- =========================================================================
-- Category II: Deep Hierarchical Graph Hydration & N+1 Prevention
-- =========================================================================

-- HQ03: 4-Level Deep Hierarchical Entity Tree Materialization
data FlightGraph = FlightGraph
  { fgFlight :: Entity Flight
  , fgLegs   :: [(Entity BookingLeg, Entity Booking, Maybe (Entity BoardingPass))]
  } deriving (Show, Eq, Generic)

assembleFlightGraph :: [(Entity Flight, Entity BookingLeg, Entity Booking, Maybe (Entity BoardingPass))] -> [FlightGraph]
assembleFlightGraph rows =
  let grouped = foldr (\(f, bl, b, mbp) acc ->
        Map.insertWith (\(fNew, legsNew) (_, legsOld) -> (fNew, legsNew ++ legsOld))
          (flightFlightId (entityVal f)) (f, [(bl, b, mbp)]) acc
        ) Map.empty rows
  in [ FlightGraph f legs | (_, (f, legs)) <- Map.toList grouped ]

hq03DeepGraphFetch :: ConnectionPool -> Int32 -> Int32 -> IO [FlightGraph]
hq03DeepGraphFetch pool minFid maxFid = do
  rows <- runSqlPool (select $ do
      (f :& bl :& b :& mbp) <- from $
          table @Flight
          `innerJoin` table @BookingLeg
              `on` (\(f :& bl) -> f ^. FlightFlightId ==. bl ^. BookingLegFlightId)
          `innerJoin` table @Booking
              `on` (\(_ :& bl :& b) -> bl ^. BookingLegBookingId ==. b ^. BookingBookingId)
          `leftJoin` table @BoardingPass
              `on` (\(_ :& bl :& _ :& bp) -> just (bl ^. BookingLegBookingLegId) ==. bp ?. BoardingPassBookingLegId)
      where_ (f ^. FlightFlightId >=. val minFid &&. f ^. FlightFlightId <=. val maxFid)
      orderBy [asc (f ^. FlightFlightId), asc (bl ^. BookingLegBookingLegId)]
      pure (f, bl, b, mbp)) pool
  pure $ assembleFlightGraph rows

-- HQ04: Account Relationship Graph with Optional Sub-Entities
data AccountGraph = AccountGraph
  { agAccount       :: Entity Account
  , agFrequentFlyer :: Maybe (Entity FrequentFlyer)
  , agBookings      :: [(Entity Booking, [Entity Passenger])]
  } deriving (Show, Eq, Generic)

assembleAccountGraph :: [(Entity Account, Maybe (Entity FrequentFlyer), Maybe (Entity Booking), Maybe (Entity Passenger))] -> [AccountGraph]
assembleAccountGraph rows =
  let accMap = foldr (\(a, mff, mb, mp) acc ->
        let entry = (mff, mb, mp)
        in Map.insertWith (\(aNew, entriesNew) (_, entriesOld) -> (aNew, entriesNew ++ entriesOld))
             (accountAccountId (entityVal a)) (a, [entry]) acc
        ) Map.empty rows
  in [ let mff = case [ff | (ff, _, _) <- entries] of
                   (Just ff : _) -> Just ff
                   _             -> Nothing
           bookings = foldr (\(_, mb, mp) bAcc ->
             case mb of
               Nothing -> bAcc
               Just b  -> Map.insertWith (\(bNew, psNew) (_, psOld) -> (bNew, psNew ++ psOld))
                            (bookingBookingId (entityVal b)) (b, maybe [] pure mp) bAcc
             ) Map.empty entries
       in AccountGraph a mff [ (b, ps) | (_, (b, ps)) <- Map.toList bookings ]
     | (_, (a, entries)) <- Map.toList accMap ]

hq04AccountGraph :: ConnectionPool -> Int32 -> Int32 -> IO [AccountGraph]
hq04AccountGraph pool minAcc maxAcc = do
  rows <- runSqlPool (select $ do
      (a :& mff :& mb :& mp) <- from $
          table @Account
          `leftJoin` table @FrequentFlyer
              `on` (\(a :& ff) -> a ^. AccountFrequentFlyerId ==. ff ?. FrequentFlyerFrequentFlyerId)
          `leftJoin` table @Booking
              `on` (\(a :& _ :& b) -> just (a ^. AccountAccountId) ==. b ?. BookingAccountId)
          `leftJoin` table @Passenger
              `on` (\(_ :& _ :& b :& p) -> b ?. BookingBookingId ==. p ?. PassengerBookingId)
      where_ (a ^. AccountAccountId >=. val minAcc &&. a ^. AccountAccountId <=. val maxAcc)
      orderBy [asc (a ^. AccountAccountId)]
      limit 7000
      pure (a, mff, mb, mp)) pool
  pure $ assembleAccountGraph rows

-- =========================================================================
-- Category III: Multi-Table Analytical Ledgers & Heavy Aggregations
-- =========================================================================

-- HQ05: Fleet & Route Profitability Analytical Ledger (5 Tables, 400k+ Rows)
data RouteLedger = RouteLedger
  { rlOrigin        :: Text
  , rlDestination   :: Text
  , rlAircraftModel :: Text
  , rlTotalFlights  :: Int64
  , rlTotalLegs     :: Int64
  , rlTotalRevenue  :: Double
  , rlAvgDelayMin   :: Double
  , rlOnTimePct     :: Double
  } deriving (Show, Eq, Generic)

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
  } deriving (Show, Eq, Generic)

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
  } deriving (Show, Eq, Generic)

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

-- =========================================================================
-- Category IV: Recursive Graph Traversal & Window Analytics
-- =========================================================================

-- HQ08: Recursive Multi-Hop Flight Connection Graph Search (1-3 Hops)
data ConnectingRoute = ConnectingRoute
  { crHops            :: Int32
  , crRoutePath       :: Text
  , crJourneyStart    :: UTCTime
  , crJourneyEnd      :: UTCTime
  , crTotalElapsedMin :: Double
  , crTotalFlightMin  :: Double
  } deriving (Show, Eq, Generic)

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
  } deriving (Show, Eq, Generic)

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
hq10KeysetPagination :: ConnectionPool -> UTCTime -> Int32 -> Int64 -> IO [Entity Flight]
hq10KeysetPagination pool cursorDate cursorId limitN = runSqlPool (select $ do
    f <- from $ table @Flight
    where_ (f ^. FlightScheduledDeparture >. val cursorDate ||.
           (f ^. FlightScheduledDeparture ==. val cursorDate &&. f ^. FlightFlightId >. val cursorId))
    orderBy [asc (f ^. FlightScheduledDeparture), asc (f ^. FlightFlightId)]
    limit limitN
    pure f) pool

-- =========================================================================
-- Category V: Dynamic Query Composition & Bulk Ingestion
-- =========================================================================

-- HQ11: High-Dimensional Dynamic Faceted Flight Search Engine (10 Optional Predicates)
data FlightSearchParams = FlightSearchParams
  { spOrigins       :: Maybe [Text]
  , spDestinations  :: Maybe [Text]
  , spMinDeparture  :: Maybe UTCTime
  , spMaxDeparture  :: Maybe UTCTime
  , spAircraftClass :: Maybe [Int32]
  , spMinRange      :: Maybe Double
  , spStatuses      :: Maybe [Text]
  , spCursor        :: Maybe (UTCTime, Int32)
  , spLimit         :: Int64
  } deriving (Show, Eq)

hq11DynamicFacetedSearch :: ConnectionPool -> FlightSearchParams -> IO [Entity Flight]
hq11DynamicFacetedSearch pool params = runSqlPool (select $ do
    (f :& ac) <- from $
        table @Flight
        `innerJoin` table @Aircraft
            `on` (\(f :& ac) -> f ^. FlightAircraftCode ==. ac ^. AircraftCode)
    case spOrigins params of
      Just origs | not (null origs) -> where_ (f ^. FlightDepartureAirport `in_` valList origs)
      _ -> pure ()
    case spDestinations params of
      Just dests | not (null dests) -> where_ (f ^. FlightArrivalAirport `in_` valList dests)
      _ -> pure ()
    case spMinDeparture params of
      Just minD -> where_ (f ^. FlightScheduledDeparture >=. val minD)
      _ -> pure ()
    case spMaxDeparture params of
      Just maxD -> where_ (f ^. FlightScheduledDeparture <=. val maxD)
      _ -> pure ()
    case spAircraftClass params of
      Just cls | not (null cls) -> where_ (ac ^. AircraftClass_ `in_` valList cls)
      _ -> pure ()
    case spMinRange params of
      Just rng -> where_ (ac ^. AircraftRange >=. val rng)
      _ -> pure ()
    case spStatuses params of
      Just sts | not (null sts) -> where_ (f ^. FlightStatus `in_` valList sts)
      _ -> pure ()
    case spCursor params of
      Just (cDate, cId) -> where_ (f ^. FlightScheduledDeparture >. val cDate ||.
                                  (f ^. FlightScheduledDeparture ==. val cDate &&. f ^. FlightFlightId >. val cId))
      _ -> pure ()
    orderBy [asc (f ^. FlightScheduledDeparture), asc (f ^. FlightFlightId)]
    limit (spLimit params)
    pure f) pool

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
  -- Reset back for future runs
  let resetQ = "UPDATE flight SET status = 'Departed', version = 1 WHERE flight_id BETWEEN ? AND ?"
  rawExecute resetQ [toPersistValue minFid, toPersistValue maxFid]
  pure (fromIntegral (length (rows :: [Single Int32])))
  ) pool

-- =========================================================================
-- Category VI: Concurrency Contention, Transactions & Multi-Modal Search
-- =========================================================================

-- HQ14: High-Concurrency Seat Allocation Under Contention (C=100)
hq14ReserveSeatConcurrent :: ConnectionPool -> Int32 -> Text -> IO (Either Text Text)
hq14ReserveSeatConcurrent pool flightId passengerName = runSqlPool (do
  rows <- rawSql
    "SELECT seat_no, version FROM flight_seat_inventory \
    \WHERE flight_id = ? AND status = 'AVAILABLE' \
    \LIMIT 1 FOR UPDATE" [toPersistValue flightId]
  case (rows :: [(Single Text, Single Int32)]) of
    [] -> pure (Left "Sold Out")
    ((Single seatNo, Single ver):_) -> do
      rawExecute
        "UPDATE flight_seat_inventory \
        \SET status = 'RESERVED', passenger_name = ?, reserved_at = clock_timestamp(), version = version + 1 \
        \WHERE flight_id = ? AND seat_no = ? AND version = ?"
        [toPersistValue passengerName, toPersistValue flightId, toPersistValue seatNo, toPersistValue ver]
      pure (Right seatNo)
  ) pool

-- HQ15: Distributed Financial / Points Transfer with Serialization Retry
hq15PointsTransferSerializable :: ConnectionPool -> Int32 -> Int32 -> Int32 -> IO (Either Text ())
hq15PointsTransferSerializable pool fromAcc toAcc points = do
  let maxRetries = 5
  let attempt n = do
        res <- try @SqlError $ runSqlPool (do
          rawExecute "SET TRANSACTION ISOLATION LEVEL SERIALIZABLE" []
          rawExecute "UPDATE frequent_flyer SET award_points = award_points - ? WHERE frequent_flyer_id = ?" [toPersistValue points, toPersistValue fromAcc]
          rawExecute "UPDATE frequent_flyer SET award_points = award_points + ? WHERE frequent_flyer_id = ?" [toPersistValue points, toPersistValue toAcc]
          -- Revert back
          rawExecute "UPDATE frequent_flyer SET award_points = award_points + ? WHERE frequent_flyer_id = ?" [toPersistValue points, toPersistValue fromAcc]
          rawExecute "UPDATE frequent_flyer SET award_points = award_points - ? WHERE frequent_flyer_id = ?" [toPersistValue points, toPersistValue toAcc]
          pure ()
          ) pool
        case res of
          Right () -> pure (Right ())
          Left err@(SqlError { sqlState = state }) ->
            if state == "40001" && n < maxRetries
              then do
                threadDelay (10000 * (2 ^ n))
                attempt (n + 1)
              else if state == "40001"
                then pure (Left "Serialization failure retry limit exceeded")
                else throwIO err
  attempt (0 :: Int)

-- HQ16: Multi-Modal Hybrid Vector Similarity + BM25 Full-Text Search with RRF Reranking
data HybridSearchResult = HybridSearchResult
  { hsrAirportCode   :: Text
  , hsrAirportName   :: Text
  , hsrCity          :: Text
  , hsrActiveFlights :: Int64
  , hsrRrfScore      :: Double
  } deriving (Show, Eq, Generic)

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
