{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecursiveDo #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

module Database.Beam.PostgresAir.Queries where

import Control.Concurrent (threadDelay)
import Control.Exception (Exception, catch, throwIO, try)
import Data.Int (Int32, Int64)
import Data.Maybe (fromMaybe)
import Data.Scientific (Scientific)
import Data.Text (Text)
import qualified Data.Text as T
import Data.Time (UTCTime)
import qualified Data.Map.Strict as Map
import Database.Beam
import Database.Beam.Backend.SQL.BeamExtensions
import Database.Beam.Postgres
import qualified Database.Beam.Postgres.Full as Pg
import Database.PostgreSQL.Simple (Connection, SqlError(..))
import qualified Database.PostgreSQL.Simple as PgSimple

import Database.Beam.PostgresAir.Schema

-- =========================================================================
-- Category I: Large-Scale Hydration, Memory & Deserialization Strain
-- =========================================================================

-- HQ01: Massive Entity Deserialization (10,000 Wide Rows)
hq01MassiveDeserialization :: Connection -> IO [Flight]
hq01MassiveDeserialization conn = runBeamPostgres conn $
  runSelectReturningList $ select $ limit_ 10000 $
    orderBy_ (asc_ . _flightId) $
    all_ (_flights postgresAirDb)

-- HQ02: Wide Multi-Join Composite Hydration (5,000 Joined Records across 4 Relations)
hq02WideJoinHydration :: Connection -> IO [(Booking, Passenger, BookingLeg, Flight)]
hq02WideJoinHydration conn = runBeamPostgres conn $
  runSelectReturningList $ select $ limit_ 5000 $
    orderBy_ (\(b, p, bl, _) -> (asc_ (_bookingId b), asc_ (_passPassengerId p), asc_ (_legBookingLegId bl))) $ do
      b <- filter_ (\x -> _bookingId x >=. val_ 100000 &&. _bookingId x <=. val_ 105000) $ all_ (_bookings postgresAirDb)
      p <- filter_ (\x -> _passBookingId x ==. _bookingId b) $ all_ (_passengers postgresAirDb)
      bl <- filter_ (\x -> _legBookingId x ==. _bookingId b) $ all_ (_bookingLegs postgresAirDb)
      f <- filter_ (\x -> _flightId x ==. _legFlightId bl) $ all_ (_flights postgresAirDb)
      pure (b, p, bl, f)

-- =========================================================================
-- Category II: Deep Hierarchical Graph Hydration & N+1 Prevention
-- =========================================================================

-- HQ03: 4-Level Deep Hierarchical Entity Tree Materialization
data FlightGraph = FlightGraph
  { fgFlight :: Flight
  , fgLegs   :: [(BookingLeg, Booking, Maybe BoardingPass)]
  } deriving (Show, Eq, Generic)

assembleFlightGraph :: [(Flight, BookingLeg, Booking, Maybe BoardingPass)] -> [FlightGraph]
assembleFlightGraph rows =
  let grouped = foldr (\(f, bl, b, mbp) acc ->
        Map.insertWith (\(fNew, legsNew) (_, legsOld) -> (fNew, legsNew ++ legsOld))
          (_flightId f) (f, [(bl, b, mbp)]) acc
        ) Map.empty rows
  in [ FlightGraph f legs | (_, (f, legs)) <- Map.toList grouped ]

hq03DeepGraphFetch :: Connection -> Int32 -> Int32 -> IO [FlightGraph]
hq03DeepGraphFetch conn minFid maxFid = do
  rows <- runBeamPostgres conn $
    runSelectReturningList $ select $
      orderBy_ (\(f, bl, _, _) -> (asc_ (_flightId f), asc_ (_legBookingLegId bl))) $ do
        f <- filter_ (\x -> _flightId x >=. val_ minFid &&. _flightId x <=. val_ maxFid) $
             all_ (_flights postgresAirDb)
        bl <- filter_ (\x -> _legFlightId x ==. _flightId f) $
              all_ (_bookingLegs postgresAirDb)
        b <- filter_ (\x -> _bookingId x ==. _legBookingId bl) $
             all_ (_bookings postgresAirDb)
        mbp <- leftJoin_ (all_ (_boardingPasses postgresAirDb))
                 (\bp -> _bpBookingLegId bp ==. _legBookingLegId bl)
        pure (f, bl, b, mbp)
  pure $ assembleFlightGraph rows

-- HQ04: Account Relationship Graph with Optional Sub-Entities
data AccountGraph = AccountGraph
  { agAccount       :: Account
  , agFrequentFlyer :: Maybe FrequentFlyer
  , agBookings      :: [(Booking, [Passenger])]
  } deriving (Show, Eq, Generic)

assembleAccountGraph :: [(Account, Maybe FrequentFlyer, Maybe Booking, Maybe Passenger)] -> [AccountGraph]
assembleAccountGraph rows =
  let accMap = foldr (\(a, mff, mb, mp) acc ->
        let entry = (mff, mb, mp)
        in Map.insertWith (\(aNew, entriesNew) (_, entriesOld) -> (aNew, entriesNew ++ entriesOld))
             (_accountId a) (a, [entry]) acc
        ) Map.empty rows
  in [ let (mff:_) = [ff | (ff, _, _) <- entries]
           bookings = foldr (\(_, mb, mp) bAcc ->
             case mb of
               Nothing -> bAcc
               Just b  -> Map.insertWith (\(bNew, psNew) (_, psOld) -> (bNew, psNew ++ psOld))
                            (_bookingId b) (b, maybe [] pure mp) bAcc
             ) Map.empty entries
       in AccountGraph a mff [ (b, ps) | (_, (b, ps)) <- Map.toList bookings ]
     | (_, (a, entries)) <- Map.toList accMap ]

hq04AccountGraph :: Connection -> Int32 -> Int32 -> IO [AccountGraph]
hq04AccountGraph conn minAcc maxAcc = do
  rows <- runBeamPostgres conn $
    runSelectReturningList $ select $
      orderBy_ (\(a, _, _, _) -> asc_ (_accountId a)) $ do
        a <- filter_ (\x -> _accountId x >=. val_ minAcc &&. _accountId x <=. val_ maxAcc) $
             all_ (_accounts postgresAirDb)
        mff <- leftJoin_ (all_ (_frequentFlyers postgresAirDb))
                 (\ff -> just_ (_ffId ff) ==. _accountFfId a)
        mb <- leftJoin_' (all_ (_bookings postgresAirDb))
                (\b -> _bookingAccountId b ==?. just_ (_accountId a))
        mp <- leftJoin_' (all_ (_passengers postgresAirDb))
                (\p -> just_ (_passBookingId p) ==?. _bookingId mb)
        pure (a, mff, mb, mp)
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

hq05RouteLedger :: Connection -> UTCTime -> UTCTime -> IO [RouteLedger]
hq05RouteLedger conn startTs endTs = do
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
  rows <- PgSimple.query conn q (startTs, endTs)
  pure [ RouteLedger o d (fromMaybe "" m) tf tl (fromMaybe 0 tr) (fromMaybe 0 ad) (fromMaybe 0 otp)
       | (o, d, m, tf, tl, tr, ad, otp) <- rows ]

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
  rows <- PgSimple.query conn q (startTs, endTs, startTs, endTs, startTs, endTs)
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
  } deriving (Show, Eq, Generic)

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
  rows <- PgSimple.query conn q (startTs, endTs)
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
  } deriving (Show, Eq, Generic)

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
  rows <- PgSimple.query conn q (origin, startTs, endTs, dest)
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
  } deriving (Show, Eq, Generic)

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
  rows <- PgSimple.query conn q (airport, startTs, endTs)
  pure [ DelayWindowAnalytics fid fno arr sched del avg5 diff std10 rank
       | (fid, fno, arr, sched, del, avg5, diff, std10, rank) <- rows ]

-- HQ10: Keyset (Cursor) Pagination over Composite Tuple Under Concurrency
hq10KeysetPagination :: Connection -> UTCTime -> Int32 -> Integer -> IO [Flight]
hq10KeysetPagination conn cursorDate cursorId limitN = runBeamPostgres conn $
  runSelectReturningList $ select $ limit_ limitN $
    orderBy_ (\f -> (asc_ (_scheduledDeparture f), asc_ (_flightId f))) $
    filter_ (\f -> _scheduledDeparture f >. val_ cursorDate ||.
                   (_scheduledDeparture f ==. val_ cursorDate &&. _flightId f >. val_ cursorId)) $
    all_ (_flights postgresAirDb)

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
  , spLimit         :: Integer
  } deriving (Show, Eq)

hq11DynamicFacetedSearch :: Connection -> FlightSearchParams -> IO [Flight]
hq11DynamicFacetedSearch conn params = runBeamPostgres conn $
  runSelectReturningList $ select $ limit_ (spLimit params) $
    orderBy_ (\f -> (asc_ (_scheduledDeparture f), asc_ (_flightId f))) $ do
      f <- all_ (_flights postgresAirDb)
      ac <- filter_ (\x -> _acCode x ==. _flightAircraftCode f) $ all_ (_aircrafts postgresAirDb)
      case spOrigins params of
        Just origs -> guard_ (_departureAirport f `in_` map val_ origs)
        Nothing    -> pure ()
      case spDestinations params of
        Just dests -> guard_ (_arrivalAirport f `in_` map val_ dests)
        Nothing    -> pure ()
      case spMinDeparture params of
        Just minD  -> guard_ (_scheduledDeparture f >=. val_ minD)
        Nothing    -> pure ()
      case spMaxDeparture params of
        Just maxD  -> guard_ (_scheduledDeparture f <=. val_ maxD)
        Nothing    -> pure ()
      case spAircraftClass params of
        Just cls   -> guard_ (_acClass ac `in_` map val_ cls)
        Nothing    -> pure ()
      case spMinRange params of
        Just rng   -> guard_ (_acRange ac >=. val_ rng)
        Nothing    -> pure ()
      case spStatuses params of
        Just sts   -> guard_ (_flightStatus f `in_` map val_ sts)
        Nothing    -> pure ()
      case spCursor params of
        Just (cDate, cId) -> guard_ (_scheduledDeparture f >. val_ cDate ||.
                                    (_scheduledDeparture f ==. val_ cDate &&. _flightId f >. val_ cId))
        Nothing    -> pure ()
      pure f

-- HQ12: High-Volume Batch Upsert (2,500 Records with Conflict Resolution)
hq12BatchUpsert :: Connection -> [FlightStatusUpdate] -> IO Int64
hq12BatchUpsert conn batch = do
  runBeamPostgres conn $ do
    runInsert $ Pg.insertOnConflict (_flightStatusUpdates postgresAirDb)
      (insertValues batch)
      (Pg.conflictingFields _fsuFlightId)
      (Pg.onConflictUpdateSet (\current excluded ->
         (_fsuStatus current <-. _fsuStatus excluded) <>
         (_fsuActualDeparture current <-. _fsuActualDeparture excluded) <>
         (_fsuActualArrival current <-. _fsuActualArrival excluded) <>
         (_fsuUpdateTs current <-. _fsuUpdateTs excluded) <>
         (_fsuVersion current <-. (current_ (_fsuVersion current) + val_ 1))))
  pure (fromIntegral (length batch))

-- HQ13: Optimistic Concurrency Bulk Fare & Status Adjustment
hq13OptimisticBulkUpdate :: Connection -> Int32 -> Int32 -> Int32 -> Text -> IO Int64
hq13OptimisticBulkUpdate conn minFid maxFid expectedVer newStatus = do
  let q = "UPDATE flight SET status = ?, version = version + 1, update_ts = clock_timestamp() \
          \WHERE flight_id BETWEEN ? AND ? AND version = ? RETURNING flight_id"
  rows <- PgSimple.query conn q (newStatus, minFid, maxFid, expectedVer) :: IO [PgSimple.Only Int32]
  pure (fromIntegral (length rows))

-- =========================================================================
-- Category VI: Concurrency Contention, Transactions & Multi-Modal Search
-- =========================================================================

-- HQ14: High-Concurrency Seat Allocation Under Contention (C=100)
hq14ReserveSeatConcurrent :: Connection -> Int32 -> Text -> IO (Either Text Text)
hq14ReserveSeatConcurrent conn flightId passengerName = do
  PgSimple.withTransaction conn $ do
    rows <- PgSimple.query conn
      "SELECT seat_no, version FROM flight_seat_inventory \
      \WHERE flight_id = ? AND status = 'AVAILABLE' \
      \LIMIT 1 FOR UPDATE" (PgSimple.Only flightId) :: IO [(Text, Int32)]
    case rows of
      [] -> pure (Left "Sold Out")
      ((seatNo, ver):_) -> do
        PgSimple.execute conn
          "UPDATE flight_seat_inventory \
          \SET status = 'RESERVED', passenger_name = ?, reserved_at = clock_timestamp(), version = version + 1 \
          \WHERE flight_id = ? AND seat_no = ? AND version = ?"
          (passengerName, flightId, seatNo, ver)
        pure (Right seatNo)

-- HQ15: Distributed Financial / Points Transfer with Serialization Retry
hq15PointsTransferSerializable :: Connection -> Int32 -> Int32 -> Int32 -> IO (Either Text ())
hq15PointsTransferSerializable conn fromAcc toAcc points = do
  let maxRetries = 5
  let attempt n = do
        res <- try @SqlError $ do
          PgSimple.withTransaction conn $ do
            _ <- PgSimple.execute_ conn "SET TRANSACTION ISOLATION LEVEL SERIALIZABLE"
            _ <- PgSimple.execute conn "UPDATE frequent_flyer SET award_points = award_points - ? WHERE frequent_flyer_id = ?" (points, fromAcc)
            _ <- PgSimple.execute conn "UPDATE frequent_flyer SET award_points = award_points + ? WHERE frequent_flyer_id = ?" (points, toAcc)
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
  attempt 0

-- HQ16: Multi-Modal Hybrid Vector Similarity + BM25 Full-Text Search with RRF Reranking
data HybridSearchResult = HybridSearchResult
  { hsrAirportCode   :: Text
  , hsrAirportName   :: Text
  , hsrCity          :: Text
  , hsrActiveFlights :: Int64
  , hsrRrfScore      :: Double
  } deriving (Show, Eq, Generic)

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
  rows <- PgSimple.query conn q (queryText, queryText, targetAirport)
  pure [ HybridSearchResult code name city flights score
       | (code, name, city, flights, score) <- rows ]
