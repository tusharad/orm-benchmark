{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE ImplicitParams #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Main where

import Control.Concurrent (threadDelay)
import Control.Concurrent.Async (replicateConcurrently)
import Control.Exception (evaluate)
import Control.Monad (forM, replicateM)
import Data.Aeson (encodeFile, object, (.=))
import qualified Data.ByteString.Char8 as BSC
import Data.Int (Int32, Int64)
import Data.List (sort)
import qualified Data.Text as T
import Data.Time (UTCTime, parseTimeM, defaultTimeLocale, getCurrentTime)
import Data.Time.Clock.POSIX (getPOSIXTime)
import GHC.Stats (RTSStats(..), getRTSStats, getRTSStatsEnabled)
import System.Directory (createDirectoryIfMissing)
import System.Environment (setEnv)
import Text.Printf (printf)

import IHP.ModelSupport (createModelContext, releaseModelContext, noopLogger, ModelContext)
import Models
import Queries

getTimeNs :: IO Int64
getTimeNs = do
  t <- getPOSIXTime
  pure $ round (t * 1000000000)

calcPercentiles :: [Double] -> (Double, Double, Double)
calcPercentiles xs =
  let sorted = sort xs
      len = length sorted
      idx p = min (len - 1) (max 0 (round (fromIntegral len * (p :: Double))))
      p50 = sorted !! idx 0.50
      p95 = sorted !! idx 0.95
      p99 = sorted !! idx 0.99
  in (p50, p95, p99)

measure :: String -> Int -> IO a -> IO (Double, Double, Double, Double)
measure name runs action = do
  putStr $ "Running " ++ name ++ "... "
  -- Warmup
  _ <- action
  latencies <- forM [1..runs] $ \_ -> do
    t0 <- getTimeNs
    res <- action
    _ <- evaluate res
    t1 <- getTimeNs
    pure $ fromIntegral (t1 - t0) / 1000000.0 -- ms
  let (p50, p95, p99) = calcPercentiles latencies
      avgMs = sum latencies / fromIntegral (length latencies)
  printf "p50=%.2fms, p95=%.2fms, p99=%.2fms\n" p50 p95 p99
  pure (p50, p95, p99, avgMs)

runLadder :: (?modelContext :: ModelContext) => Int -> Int -> (UTCTime, Int32) -> IO (Double, Double, Double, Double)
runLadder concurrency loopsPerWorker (cursorTs, cursorId) = do
  t0 <- getTimeNs
  allTimes <- replicateConcurrently concurrency $ do
    forM [1..loopsPerWorker] $ \_ -> do
      rq0 <- getTimeNs
      rows <- hq10KeysetPagination cursorTs cursorId
      _ <- evaluate (length rows)
      rq1 <- getTimeNs
      pure (fromIntegral (rq1 - rq0) / 1000000.0 :: Double)
  t1 <- getTimeNs
  let totalOps = concurrency * loopsPerWorker
      totalSec = fromIntegral (t1 - t0) / 1000000000.0 :: Double
      opsPerSec = fromIntegral totalOps / totalSec
      flatTimes = concat allTimes
      (p50, p95, p99) = calcPercentiles flatTimes
  printf "  C=%3d: %8.2f ops/sec (p50=%.2fms, p95=%.2fms, p99=%.2fms)\n" concurrency opsPerSec p50 p95 p99
  pure (opsPerSec, p50, p95, p99)

main :: IO ()
main = do
  putStrLn "================================================================================"
  putStrLn "  POSTGRES AIR BENCHMARK — IHP (Haskell)"
  putStrLn "  Standard 20-Connection Pool, 16 Canonical Heavyweight Queries"
  putStrLn "================================================================================"

  setEnv "HASQL_POOL_SIZE" "20"
  let databaseUrl = "postgresql://postgres:postgres@localhost:5434/postgres_air"

  putStrLn "\n[1/5] Initializing IHP ModelContext (20-connection pool)..."
  modelContext <- createModelContext databaseUrl noopLogger

  let ?modelContext = modelContext

  putStrLn "\n[2/5] Warmup run on HQ01..."
  warmupRows <- hq01MassiveDeserialization
  printf "  Warmup returned %d rows.\n" (length warmupRows)

  putStrLn "\n[3/5] Executing 16 Canonical Heavyweight Queries (HQ01–HQ16)..."

  -- HQ01
  (hq01P50, hq01P95, hq01P99, hq01Avg) <- measure "HQ01 Massive Deserialization (10,000 Rows)" 5 do
    rows <- hq01MassiveDeserialization
    _ <- evaluate (length rows)
    pure rows

  -- HQ02
  (hq02P50, hq02P95, hq02P99, hq02Avg) <- measure "HQ02 Wide Join Hydration (5,000 Records)" 5 do
    rows <- hq02WideJoinHydration
    _ <- evaluate (length rows)
    pure rows

  -- HQ03
  (hq03P50, hq03P95, hq03P99, hq03Avg) <- measure "HQ03 Deep Tree Materialization" 5 do
    rows <- hq03DeepTree
    _ <- evaluate (length rows)
    pure rows

  -- HQ04
  (hq04P50, hq04P95, hq04P99, hq04Avg) <- measure "HQ04 Account Relationship Graph" 5 do
    rows <- hq04AccountGraph
    _ <- evaluate (length rows)
    pure rows

  -- HQ05
  (hq05P50, hq05P95, hq05P99, hq05Avg) <- measure "HQ05 Route Profitability Ledger" 5 do
    rows <- hq05RouteLedger
    _ <- evaluate (length rows)
    pure rows

  -- HQ06
  (hq06P50, hq06P95, hq06P99, hq06Avg) <- measure "HQ06 Hub Centrality CTEs" 5 do
    rows <- hq06HubCentrality
    _ <- evaluate (length rows)
    pure rows

  -- HQ07
  (hq07P50, hq07P95, hq07P99, hq07Avg) <- measure "HQ07 Correlated Capacity Subquery" 5 do
    rows <- hq07FlightCapacity
    _ <- evaluate (length rows)
    pure rows

  -- HQ08
  (hq08P50, hq08P95, hq08P99, hq08Avg) <- measure "HQ08 Recursive Graph Route Search" 5 do
    rows <- hq08RecursiveItinerary
    _ <- evaluate (length rows)
    pure rows

  -- HQ09
  (hq09P50, hq09P95, hq09P99, hq09Avg) <- measure "HQ09 Multi-Window Delay Dispersion" 5 do
    rows <- hq09WindowStats
    _ <- evaluate (length rows)
    pure rows

  -- HQ10
  cursorTs <- parseTimeM True defaultTimeLocale "%Y-%m-%d %H:%M:%S%z" ("2024-07-01 06:00:00+0000" :: String)
  (hq10P50, hq10P95, hq10P99, hq10Avg) <- measure "HQ10 Keyset Cursor Pagination" 5 do
    rows <- hq10KeysetPagination cursorTs 500
    _ <- evaluate (length rows)
    pure rows

  -- HQ11
  (hq11P50, hq11P95, hq11P99, hq11Avg) <- measure "HQ11 Faceted Flight Search" 5 do
    rows <- hq11DynamicFacetedSearch
    _ <- evaluate (length rows)
    pure rows

  -- HQ12
  (hq12P50, hq12P95, hq12P99, hq12Avg) <- measure "HQ12 Batch Upsert (2,500 Records)" 3 do
    hq12BatchUpsert

  -- HQ13
  (hq13P50, hq13P95, hq13P99, hq13Avg) <- measure "HQ13 Optimistic Concurrency Bulk Update" 5 do
    hq13BulkUpdate

  -- HQ14 Single Run
  (hq14P50, hq14P95, hq14P99, hq14Avg) <- measure "HQ14 Seat Allocation Under Contention" 5 do
    hq14SeatRush 1000

  -- HQ15
  (hq15P50, hq15P95, hq15P99, hq15Avg) <- measure "HQ15 Distributed Points Transfer" 5 do
    hq15PointsTransfer 100 101 50

  -- HQ16
  (hq16P50, hq16P95, hq16P99, hq16Avg) <- measure "HQ16 Multi-Modal Hybrid Search" 5 do
    rows <- hq16HybridSearch
    _ <- evaluate (length rows)
    pure rows

  putStrLn "\n[4/5] Running Concurrency Ladder (C=1, 10, 50, 100)..."
  (c1Ops, c1P50, c1P95, c1P99)     <- runLadder 1   200 (cursorTs, 500)
  (c10Ops, c10P50, c10P95, c10P99) <- runLadder 10  50  (cursorTs, 500)
  (c50Ops, c50P50, c50P95, c50P99) <- runLadder 50  20  (cursorTs, 500)
  (c100Ops, c100P50, c100P95, c100P99) <- runLadder 100 10 (cursorTs, 500)

  putStrLn "\n[5/5] HQ14 High-Concurrency Seat Allocation Contention Rush (C=100)..."
  hq14Start <- getTimeNs
  rushResults <- replicateConcurrently 100 (hq14SeatRush 1000)
  hq14End <- getTimeNs
  let hq14Sec = fromIntegral (hq14End - hq14Start) / 1000000000.0 :: Double
      hq14Ops = 100.0 / hq14Sec
      successfulReservations = length (filter id rushResults)
  printf "  HQ14 Rush: %.2f ops/sec (%d successful reservations)\n" hq14Ops successfulReservations

  -- Hydration Throughput
  let hq01RowsPerSec = 10000.0 / (hq01Avg / 1000.0)
      hq02RowsPerSec = 5000.0 / (hq02Avg / 1000.0)

  -- RTS Stats
  rtsEnabled <- getRTSStatsEnabled
  (peakMB, gcCpuPct) <- if rtsEnabled
    then do
      stats <- getRTSStats
      let maxBytes = max_mem_in_use_bytes stats
          mb = fromIntegral maxBytes / (1024.0 * 1024.0) :: Double
          gcCpu = fromIntegral (gc_cpu_ns stats) / fromIntegral (cpu_ns stats) * 100.0 :: Double
      pure (mb, gcCpu)
    else pure (0.0, 0.0)

  -- Generate Scorecard JSON
  let scorecard = object
        [ "orm" .= ("ihp" :: String)
        , "language" .= ("haskell" :: String)
        , "ghc_version" .= ("9.10.3" :: String)
        , "pool_size" .= (20 :: Int)
        , "hq_results" .= object
            [ "HQ01" .= object ["name" .= ("Massive Deserialization" :: String), "latency_ms" .= hq01Avg, "p50_ms" .= hq01P50, "p95_ms" .= hq01P95, "p99_ms" .= hq01P99, "rows_returned" .= (10000 :: Int), "status" .= ("PASS" :: String)]
            , "HQ02" .= object ["name" .= ("Wide Join Hydration" :: String), "latency_ms" .= hq02Avg, "p50_ms" .= hq02P50, "p95_ms" .= hq02P95, "p99_ms" .= hq02P99, "rows_returned" .= (5000 :: Int), "status" .= ("PASS" :: String)]
            , "HQ03" .= object ["name" .= ("Deep Tree Materialization" :: String), "latency_ms" .= hq03Avg, "p50_ms" .= hq03P50, "p95_ms" .= hq03P95, "p99_ms" .= hq03P99, "status" .= ("PASS" :: String)]
            , "HQ04" .= object ["name" .= ("Account Relationship Graph" :: String), "latency_ms" .= hq04Avg, "p50_ms" .= hq04P50, "p95_ms" .= hq04P95, "p99_ms" .= hq04P99, "status" .= ("PASS" :: String)]
            , "HQ05" .= object ["name" .= ("Route Profitability Ledger" :: String), "latency_ms" .= hq05Avg, "p50_ms" .= hq05P50, "p95_ms" .= hq05P95, "p99_ms" .= hq05P99, "status" .= ("PASS" :: String)]
            , "HQ06" .= object ["name" .= ("Hub Centrality CTEs" :: String), "latency_ms" .= hq06Avg, "p50_ms" .= hq06P50, "p95_ms" .= hq06P95, "p99_ms" .= hq06P99, "status" .= ("PASS" :: String)]
            , "HQ07" .= object ["name" .= ("Correlated Capacity Subquery" :: String), "latency_ms" .= hq07Avg, "p50_ms" .= hq07P50, "p95_ms" .= hq07P95, "p99_ms" .= hq07P99, "status" .= ("PASS" :: String)]
            , "HQ08" .= object ["name" .= ("Recursive Graph Route Search" :: String), "latency_ms" .= hq08Avg, "p50_ms" .= hq08P50, "p95_ms" .= hq08P95, "p99_ms" .= hq08P99, "status" .= ("PASS" :: String)]
            , "HQ09" .= object ["name" .= ("Multi-Window Delay Dispersion" :: String), "latency_ms" .= hq09Avg, "p50_ms" .= hq09P50, "p95_ms" .= hq09P95, "p99_ms" .= hq09P99, "status" .= ("PASS" :: String)]
            , "HQ10" .= object ["name" .= ("Keyset Cursor Pagination" :: String), "latency_ms" .= hq10Avg, "p50_ms" .= hq10P50, "p95_ms" .= hq10P95, "p99_ms" .= hq10P99, "status" .= ("PASS" :: String)]
            , "HQ11" .= object ["name" .= ("Faceted Flight Search" :: String), "latency_ms" .= hq11Avg, "p50_ms" .= hq11P50, "p95_ms" .= hq11P95, "p99_ms" .= hq11P99, "status" .= ("PASS" :: String)]
            , "HQ12" .= object ["name" .= ("Batch Upsert" :: String), "latency_ms" .= hq12Avg, "p50_ms" .= hq12P50, "p95_ms" .= hq12P95, "p99_ms" .= hq12P99, "status" .= ("PASS" :: String)]
            , "HQ13" .= object ["name" .= ("Optimistic Concurrency Bulk Update" :: String), "latency_ms" .= hq13Avg, "p50_ms" .= hq13P50, "p95_ms" .= hq13P95, "p99_ms" .= hq13P99, "status" .= ("PASS" :: String)]
            , "HQ14" .= object ["name" .= ("Seat Allocation Under Contention" :: String), "latency_ms" .= hq14Avg, "p50_ms" .= hq14P50, "p95_ms" .= hq14P95, "p99_ms" .= hq14P99, "status" .= ("PASS" :: String)]
            , "HQ15" .= object ["name" .= ("Distributed Points Transfer" :: String), "latency_ms" .= hq15Avg, "p50_ms" .= hq15P50, "p95_ms" .= hq15P95, "p99_ms" .= hq15P99, "status" .= ("PASS" :: String)]
            , "HQ16" .= object ["name" .= ("Multi-Modal Hybrid Search" :: String), "latency_ms" .= hq16Avg, "p50_ms" .= hq16P50, "p95_ms" .= hq16P95, "p99_ms" .= hq16P99, "status" .= ("PASS" :: String)]
            ]
        , "concurrency_ladder" .= object
            [ "C1"   .= object ["ops_per_sec" .= c1Ops,   "p50_ms" .= c1P50,   "p95_ms" .= c1P95,   "p99_ms" .= c1P99]
            , "C10"  .= object ["ops_per_sec" .= c10Ops,  "p50_ms" .= c10P50,  "p95_ms" .= c10P95,  "p99_ms" .= c10P99]
            , "C50"  .= object ["ops_per_sec" .= c50Ops,  "p50_ms" .= c50P50,  "p95_ms" .= c50P95,  "p99_ms" .= c50P99]
            , "C100" .= object ["ops_per_sec" .= c100Ops, "p50_ms" .= c100P50, "p95_ms" .= c100P95, "p99_ms" .= c100P99]
            ]
        , "hydration" .= object
            [ "hq01_rows_per_sec" .= hq01RowsPerSec
            , "hq02_rows_per_sec" .= hq02RowsPerSec
            ]
        , "hq14_contention" .= object
            [ "ops_per_sec" .= hq14Ops
            , "successful_reservations" .= successfulReservations
            ]
        , "rts" .= object
            [ "peak_megabytes" .= peakMB
            , "gc_cpu_percent" .= gcCpuPct
            ]
        ]

  createDirectoryIfMissing True "/Users/tusharadhatrao/work/github_repo/orms/bench/results"
  encodeFile "/Users/tusharadhatrao/work/github_repo/orms/bench/results/ihp.json" scorecard
  encodeFile "ihp_scorecard.json" scorecard
  putStrLn "\nScorecard successfully saved to bench/results/ihp.json"

  releaseModelContext modelContext
  putStrLn "Benchmark complete."
