{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

module Database.Opaleye.PostgresAir.Queries where

import Control.Concurrent (threadDelay)
import Control.DeepSeq (NFData)
import Control.Exception (Exception, catch, throwIO, try)
import Data.Int (Int32, Int64)
import qualified Data.Map.Strict as Map
import Data.Maybe (fromMaybe)
import Data.Scientific (Scientific)
import Data.Text (Text)
import qualified Data.Text as T
import Data.Time (UTCTime, getCurrentTime)
import Database.PostgreSQL.Simple (Connection, SqlError(..), FromRow, ToRow, query, query_, execute, execute_)
import qualified Database.PostgreSQL.Simple as PGS
import GHC.Generics (Generic)
import Opaleye
import Opaleye.Internal.Column (unsafeFromNullable)

import Database.Opaleye.PostgresAir.Schema

-- =========================================================================
-- Category I: Large-Scale Hydration, Memory & Deserialization Strain
-- =========================================================================

-- HQ01: Massive Entity Deserialization (10,000 Wide Rows)
hq01Select :: Select FlightField
hq01Select = limit 10000 $ orderBy (asc flightId) (selectTable flightTable)

hq01MassiveDeserialization :: Connection -> IO [Flight]
hq01MassiveDeserialization conn = runSelect conn hq01Select

-- HQ02: Wide Multi-Join Composite Hydration (5,000 Joined Records across 4 Relations)
hq02Select :: Select (BookingField, PassengerField, BookingLegField, FlightField)
hq02Select = limit 5000 $ orderBy (asc (\(b, _, _, _) -> bookingId b) <> asc (\(_, p, _, _) -> passengerId p) <> asc (\(_, _, bl, _) -> bookingLegId bl)) $ do
  b <- selectTable bookingTable
  p <- selectTable passengerTable
  bl <- selectTable bookingLegTable
  f <- selectTable flightTable
  where_ (bookingId b .== pBookingId p)
  where_ (bookingId b .== blBookingId bl)
  where_ (blFlightId bl .== flightId f)
  where_ (bookingId b .>= toFields (100000 :: Int64) .&& bookingId b .<= toFields (105000 :: Int64))
  pure (b, p, bl, f)

hq02WideJoinHydration :: Connection -> IO [(Booking, Passenger, BookingLeg, Flight)]
hq02WideJoinHydration conn = runSelect conn hq02Select

-- =========================================================================
-- Category II: Deep Hierarchical Graph Hydration & N+1 Prevention
-- =========================================================================

-- HQ03: 4-Level Deep Hierarchical Entity Tree Materialization
data FlightGraph = FlightGraph
  { fgFlight :: Flight
  , fgLegs   :: [(BookingLeg, Booking, Maybe BoardingPass)]
  } deriving (Show, Eq, Generic, NFData)

assembleFlightGraph :: [(Flight, BookingLeg, Booking, Maybe BoardingPass)] -> [FlightGraph]
assembleFlightGraph rows =
  let grouped = foldr (\(f, bl, b, mbp) acc ->
        Map.insertWith (\(fNew, legsNew) (_, legsOld) -> (fNew, legsNew ++ legsOld))
          (flightId f) (f, [(bl, b, mbp)]) acc
        ) Map.empty rows
  in [ FlightGraph f legs | (_, (f, legs)) <- Map.toList grouped ]

hq03Select :: Int32 -> Int32 -> Select (FlightField, BookingLegField, BookingField, MaybeFields BoardingPassField)
hq03Select minFid maxFid = orderBy (asc (\(f, _, _, _) -> flightId f) <> asc (\(_, bl, _, _) -> bookingLegId bl)) $ do
  f <- selectTable flightTable
  where_ (flightId f .>= toFields minFid .&& flightId f .<= toFields maxFid)
  bl <- selectTable bookingLegTable
  where_ (flightId f .== blFlightId bl)
  b <- selectTable bookingTable
  where_ (blBookingId bl .== bookingId b)
  mbp <- optional $ do
    bp <- selectTable boardingPassTable
    where_ (matchNullable (toFields False) (\legId -> bookingLegId bl .== legId) (bpBookingLeg bp))
    where_ (bookingLegId bl .== unsafeFromNullable (bpBookingLeg bp))
    pure bp
  pure (f, bl, b, mbp)

hq03DeepGraphFetch :: Connection -> Int32 -> Int32 -> IO [FlightGraph]
hq03DeepGraphFetch conn minFid maxFid = do
  rows <- runSelect conn (hq03Select minFid maxFid)
  pure $ assembleFlightGraph rows

-- HQ04: Account Relationship Graph with Optional Sub-Entities
data AccountGraph = AccountGraph
  { agAccount       :: Account
  , agFrequentFlyer :: Maybe FrequentFlyer
  , agBookings      :: [(Booking, [Passenger])]
  } deriving (Show, Eq, Generic, NFData)

assembleAccountGraph :: [(Account, Maybe FrequentFlyer, Maybe (Booking, Maybe Passenger))] -> [AccountGraph]
assembleAccountGraph rows =
  let accMap = foldr (\(a, mff, mbp) acc ->
        Map.insertWith (\(aNew, entriesNew) (_, entriesOld) -> (aNew, entriesNew ++ entriesOld))
          (accAccountId a) (a, [(mff, mbp)]) acc
        ) Map.empty rows
  in [ let mff = case [ff | (ff, _) <- entries] of
                   (f:_) -> f
                   []    -> Nothing
           bookings = foldr (\(_, mbp) bAcc ->
             case mbp of
               Nothing -> bAcc
               Just (b, mp) ->
                 Map.insertWith (\(bNew, psNew) (_, psOld) -> (bNew, psNew ++ psOld))
                   (bookingId b) (b, maybe [] pure mp) bAcc
             ) Map.empty entries
       in AccountGraph a mff [ (b, ps) | (_, (b, ps)) <- Map.toList bookings ]
     | (_, (a, entries)) <- Map.toList accMap ]

hq04Select :: Int32 -> Int32 -> Select (AccountField, MaybeFields FrequentFlyerField, MaybeFields (BookingField, MaybeFields PassengerField))
hq04Select minAcc maxAcc = orderBy (asc (\(a, _, _) -> accAccountId a)) $ do
  a <- selectTable accountTable
  where_ (accAccountId a .>= toFields minAcc .&& accAccountId a .<= toFields maxAcc)
  mff <- optional $ do
    ff <- selectTable frequentFlyerTable
    where_ (matchNullable (toFields False) (\ffId -> ffFrequentFlyerId ff .== ffId) (frequentFlyerId a))
    where_ (ffFrequentFlyerId ff .== unsafeFromNullable (frequentFlyerId a))
    pure ff
  mbp <- optional $ do
    b <- selectTable bookingTable
    where_ (matchNullable (toFields False) (\accId -> accAccountId a .== accId) (accountId b))
    where_ (accAccountId a .== unsafeFromNullable (accountId b))
    mp <- optional $ do
      p <- selectTable passengerTable
      where_ (bookingId b .== pBookingId p)
      pure p
    pure (b, mp)
  pure (a, mff, mbp)

hq04AccountGraph :: Connection -> Int32 -> Int32 -> IO [AccountGraph]
hq04AccountGraph conn minAcc maxAcc = do
  rows <- runSelect conn (hq04Select minAcc maxAcc)
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
  } deriving (Show, Eq, Generic, NFData)

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

-- HQ06: Chained Multi-Stage CTEs (Hub Centrality & Degree)
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
  } deriving (Show, Eq, Generic, NFData)

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

-- HQ10: Keyset (Cursor) Pagination over Composite Tuple Under Concurrency
hq10Select :: UTCTime -> Int32 -> Int -> Select FlightField
hq10Select cTime cId limitCount = limit limitCount $ orderBy (asc scheduledDeparture <> asc flightId) $ do
  f <- selectTable flightTable
  where_ (scheduledDeparture f .> toFields cTime .|| (scheduledDeparture f .== toFields cTime .&& flightId f .> toFields cId))
  pure f

hq10KeysetPagination :: Connection -> UTCTime -> Int32 -> Int -> IO [Flight]
hq10KeysetPagination conn cTime cId limitCount = runSelect conn (hq10Select cTime cId limitCount)

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
  , spMinRange      :: Maybe Scientific
  , spStatuses      :: Maybe [Text]
  , spCursor        :: Maybe (UTCTime, Int32)
  , spLimit         :: Int
  } deriving (Show, Eq, Generic)

hq11Select :: FlightSearchParams -> Select FlightField
hq11Select params = limit (spLimit params) $
  orderBy (asc scheduledDeparture <> asc flightId) $ do
    f <- selectTable flightTable
    ac <- selectTable aircraftTable
    where_ (aircraftCode f .== aircraftCode_ ac)
    case spOrigins params of
      Just origs -> where_ (inMany (map toFields origs) (departureAirport f))
      Nothing    -> pure ()
    case spDestinations params of
      Just dests -> where_ (inMany (map toFields dests) (arrivalAirport f))
      Nothing    -> pure ()
    case spMinDeparture params of
      Just minD  -> where_ (scheduledDeparture f .>= toFields minD)
      Nothing    -> pure ()
    case spMaxDeparture params of
      Just maxD  -> where_ (scheduledDeparture f .<= toFields maxD)
      Nothing    -> pure ()
    case spAircraftClass params of
      Just cls   -> where_ (inMany (map toFields cls) (aircraftClass ac))
      Nothing    -> pure ()
    case spMinRange params of
      Just rng   -> where_ (aircraftRange ac .>= toFields rng)
      Nothing    -> pure ()
    case spStatuses params of
      Just sts   -> where_ (inMany (map toFields sts) (status f))
      Nothing    -> pure ()
    case spCursor params of
      Just (cDate, cId) ->
        where_ (scheduledDeparture f .> toFields cDate .|| (scheduledDeparture f .== toFields cDate .&& flightId f .> toFields cId))
      Nothing    -> pure ()
    pure f

hq11DynamicFacetedSearch :: Connection -> FlightSearchParams -> IO [Flight]
hq11DynamicFacetedSearch conn params = runSelect conn (hq11Select params)

-- HQ12: High-Volume Batch Upsert (2,500 Records with Conflict Resolution)
hq12BatchUpsert :: Connection -> [FlightStatusUpdate] -> IO Int64
hq12BatchUpsert conn batch = do
  let q = "INSERT INTO postgres_air.flight_status_update (flight_id, status, actual_departure, actual_arrival, update_ts, version) \
          \VALUES (?, ?, ?, ?, ?, ?) \
          \ON CONFLICT (flight_id) DO UPDATE SET \
          \  status = EXCLUDED.status, \
          \  actual_departure = EXCLUDED.actual_departure, \
          \  actual_arrival = EXCLUDED.actual_arrival, \
          \  update_ts = EXCLUDED.update_ts, \
          \  version = postgres_air.flight_status_update.version + 1"
  let params = [ (fsuFlightId u, fsuStatus u, fsuActualDeparture u, fsuActualArrival u, fsuUpdateTs u, fsuVersion u) | u <- batch ]
  PGS.executeMany conn q params

-- HQ13: Optimistic Concurrency Bulk Fare & Status Adjustment
hq13OptimisticBulkUpdate :: Connection -> Int32 -> Int32 -> Int32 -> Text -> IO Int64
hq13OptimisticBulkUpdate conn minFid maxFid expectedVer newStatus = do
  let q = "UPDATE flight SET status = ?, version = version + 1, update_ts = clock_timestamp() \
          \WHERE flight_id BETWEEN ? AND ? AND version = ? RETURNING flight_id"
  rows <- PGS.query conn q (newStatus, minFid, maxFid, expectedVer) :: IO [PGS.Only Int32]
  pure (fromIntegral (length rows))

-- =========================================================================
-- Category VI: Concurrency Contention, Transactions & Multi-Modal Search
-- =========================================================================

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
                else throwIO err
  attempt (0 :: Int)

-- HQ16: Multi-Modal Hybrid Vector Similarity + BM25 Full-Text Search with RRF Reranking
data HybridSearchResult = HybridSearchResult
  { hsrAirportCode   :: Text
  , hsrAirportName   :: Text
  , hsrCity          :: Text
  , hsrActiveFlights :: Int64
  , hsrRrfScore      :: Double
  } deriving (Show, Eq, Generic, NFData)

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
