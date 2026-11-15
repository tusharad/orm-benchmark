# Heavyweight ORM Benchmark Specification & Rules

This document specifies the standard methodology, test suites, evaluation metrics, and scoring rules for benchmarking Object-Relational Mappings (ORMs) against the **Postgres Air** database (78+ Million rows).

---

## 1. Benchmark Objectives & Stress Dimensions

Traditional ORM benchmarks often test trivial single-row primary key lookups (`SELECT * FROM table WHERE id = 1`), which only measure database network round-trip time and fail to expose the real performance, architectural, and ergonomic differences between ORMs.

This benchmark suite is engineered specifically to **put real strain on ORMs across 6 critical stress dimensions**:

1. **Massive Hydration & Deserialization Strain**: Ingesting thousands of wide records into strongly-typed language records/structs, measuring heap allocation spikes, GC pressure (minor/major collections, pause duration), and CPU decoding throughput (MB/sec and rows/sec).
2. **Deep Hierarchical Graph Materialization & N+1 Prevention**: Materializing 4-level deep entity trees (e.g. Flight $\to$ BookingLeg $\to$ Booking $\to$ BoardingPass) without triggering $N+1$ query floods, Cartesian memory blowups, or untyped manual stitching.
3. **Multi-Table Analytical Ledgers & Heavy Aggregations**: 5- to 7-table analytical joins scanning hundreds of thousands of records, computing multi-column aggregations, conditional filters (`FILTER (WHERE ...)` or `SUM(CASE WHEN ...)`), and `HAVING` clauses.
4. **Recursive Graph Traversal & Advanced Window Analytics**: Multi-hop dynamic path-finding CTEs with layover constraints and cycle detection, plus multi-frame window functions (`ROWS BETWEEN`, `LAG`, `DENSE_RANK`, rolling standard deviations).
5. **High-Volume Bulk Mutations & Dynamic DSL Composition**: Multi-row batched upserts ($N=2,500$ rows) with conflict resolution, and dynamic faceted query engines supporting 10+ optional predicates without string concatenation or SQL injection vulnerabilities.
6. **High-Concurrency Contention & Tail Latency**: Multi-client concurrent transactions ($C=50, 100$) competing for constrained resources (e.g., flight seat inventory) with row-level locks (`SELECT ... FOR UPDATE`) or optimistic serialization retry on code `40001`.

---

## 2. Environment & Execution Protocol

### 2.1 Database & Host
- **Database**: PostgreSQL 17 with `pgvector` extension (`pgvector/pgvector:pg17`), running in Docker.
- **Port**: `5434` on `localhost`.
- **Database Name**: `postgres_air`.
- **Credentials**: `postgres` / `postgres`.
- **Default `search_path`**: `postgres_air, public`.
- **Total Data Volume**: 78+ Million rows (~8 GB active dataset).

### 2.2 Benchmarking Invariants (Fairness Rules)
1. **Native DSL / Query Builder Usage**: All queries must be expressed using the ORM's native typed query builder, DSL, or entity representations. **Raw SQL string interpolation is strictly disallowed** except where an ORM explicitly delegates a specific unsupported Postgres operator (e.g., custom vector distance `<=>`).
2. **Type Hydration**: Queries must deserialize database rows into native language types/records/structs, not generic untyped dictionaries or dynamic tuples.
3. **Connection Pooling**: Every ORM must use a standardized connection pool of **20 connections**, with a connection timeout of 10 seconds.
4. **Warmup & Measurement Protocol**:
   - **Warmup**: Minimum 50 iterations per query (or 3 seconds) before recording metrics.
   - **Measurement**: Minimum 200 iterations per query (or 10 seconds) for latency percentiles.
   - **Isolation**: Each benchmark category (single-query latency, concurrency, memory profiling) must run in isolated processes to prevent GC or memory cache cross-contamination.

---

## 3. The 16 Heavyweight Canonical Queries (HQ01–HQ16)

Every ORM implements the exact same 16 real-world queries on the PostgresAir schema.

---

### Category I: Large-Scale Hydration, Memory & Deserialization Strain (HQ01–HQ02)

#### **HQ01: Massive Entity Deserialization (10,000 Wide Rows)**
- **Strain Dimension**: Tests raw decoding speed, memory allocation rate, string/timestamp parsing, and GC pressure when materializing 10,000 full domain entity objects (120,000 native fields).
- **Output Type**: `[Flight]` (list of 10,000 fully hydrated domain records).
- **Reference SQL**:
  ```sql
  SELECT flight_id, flight_no, scheduled_departure, scheduled_arrival,
         departure_airport, arrival_airport, status, aircraft_code,
         actual_departure, actual_arrival, update_ts, version
  FROM flight
  ORDER BY flight_id
  LIMIT 10000;
  ```

#### **HQ02: Wide Multi-Join Composite Hydration (5,000 Joined Records Across 4 Relations)**
- **Strain Dimension**: Tests deserialization of heterogeneous joined records with nullable foreign keys and numeric values (17 columns $\times$ 5,000 rows = 85,000 fields).
- **Output Type**: List of 5,000 composite records containing Booking, Passenger, BookingLeg, and Flight fields.
- **Reference SQL**:
  ```sql
  SELECT b.booking_id, b.booking_ref, b.price, b.email,
         p.passenger_id, p.first_name, p.last_name, p.age,
         bl.booking_leg_id, bl.leg_num, bl.is_returning,
         f.flight_id, f.flight_no, f.departure_airport, f.arrival_airport, 
         f.scheduled_departure, f.status
  FROM booking b
  JOIN passenger p ON b.booking_id = p.booking_id
  JOIN booking_leg bl ON b.booking_id = bl.booking_id
  JOIN flight f ON bl.flight_id = f.flight_id
  WHERE b.booking_id BETWEEN 100000 AND 105000
  ORDER BY b.booking_id, p.passenger_id, bl.booking_leg_id
  LIMIT 5000;
  ```

---

### Category II: Deep Hierarchical Graph Hydration & N+1 Prevention (HQ03–HQ04)

#### **HQ03: 4-Level Deep Hierarchical Entity Tree Materialization**
- **Strain Dimension**: Tests ORM's ability to assemble a nested domain graph (Flight $\to$ BookingLeg $\to$ Booking $\to$ BoardingPass) containing 2,200+ distinct domain objects across 25 flights without triggering $N+1$ queries or Cartesian memory blowups.
- **Input**: `flight_id` range $[2000, 2025]$
- **Output Type**: Nested graph structure:
  ```haskell
  data FlightGraph = FlightGraph {
      flight :: Flight,
      legs   :: [BookingLegNode]
  }
  data BookingLegNode = BookingLegNode {
      leg          :: BookingLeg,
      booking      :: Booking,
      boardingPass :: Maybe BoardingPass
  }
  ```
- **Reference SQL**:
  ```sql
  SELECT f.flight_id, f.flight_no, f.departure_airport, f.arrival_airport, f.scheduled_departure,
         bl.booking_leg_id, bl.leg_num,
         b.booking_id, b.booking_ref, b.price,
         bp.pass_id, bp.seat, bp.boarding_time
  FROM flight f
  JOIN booking_leg bl ON f.flight_id = bl.flight_id
  JOIN booking b ON bl.booking_id = b.booking_id
  LEFT JOIN boarding_pass bp ON (bp.booking_leg_id = bl.booking_leg_id)
  WHERE f.flight_id BETWEEN 2000 AND 2025
  ORDER BY f.flight_id, bl.booking_leg_id, bp.pass_id;
  ```

#### **HQ04: Account Relationship Graph with Optional Sub-Entities**
- **Strain Dimension**: Materializes 200 accounts along with optional frequent flyer profiles, phone records, and booking history (7,000+ joined records), testing null-propagation across deep relation trees.
- **Input**: `account_id` range $[50000, 50200]$
- **Output Type**: Hierarchical Account model with nested collections.
- **Reference SQL**:
  ```sql
  SELECT a.account_id, a.login, a.first_name, a.last_name,
         ff.frequent_flyer_id, ff.level AS ff_level, ff.award_points,
         ph.phone_id, ph.phone, ph.phone_type,
         b.booking_id, b.booking_ref, b.price AS booking_price,
         p.passenger_id, p.first_name AS passenger_first_name, p.last_name AS passenger_last_name
  FROM account a
  LEFT JOIN frequent_flyer ff ON a.frequent_flyer_id = ff.frequent_flyer_id
  LEFT JOIN phone ph ON a.account_id = ph.account_id
  LEFT JOIN booking b ON a.account_id = b.account_id
  LEFT JOIN passenger p ON b.booking_id = p.booking_id
  WHERE a.account_id BETWEEN 50000 AND 50200
  ORDER BY a.account_id, ph.phone_id, b.booking_id, p.passenger_id;
  ```

---

### Category III: Multi-Table Analytical Ledgers & Heavy Aggregations (HQ05–HQ07)

#### **HQ05: Fleet & Route Profitability Analytical Ledger (5-Table Join over 400k+ Rows)**
- **Strain Dimension**: Joins 5 tables (`flight`, `airport` origin, `airport` dest, `aircraft`, `booking_leg`, `booking`) over a 3-day flight window (410,000+ records). Computes distinct counts, sums, averages, and conditional percentage metrics (`FILTER`/`CASE`), grouped by 3 dimensions with `HAVING`.
- **Output Type**: List of RouteFinancialLedger records (top 50 by total revenue).
- **Reference SQL**:
  ```sql
  SELECT orig.airport_code AS origin,
         dest.airport_code AS destination,
         ac.model AS aircraft_model,
         count(DISTINCT f.flight_id) AS total_flights,
         count(bl.booking_leg_id) AS total_legs_booked,
         round(sum(b.price), 2) AS total_revenue,
         round(avg(EXTRACT(EPOCH FROM (f.actual_departure - f.scheduled_departure)) / 60), 2) AS avg_delay_minutes,
         round(100.0 * count(CASE WHEN f.actual_departure <= f.scheduled_departure + INTERVAL '15 minutes' THEN 1 END) / count(f.flight_id), 2) AS on_time_pct
  FROM flight f
  JOIN airport orig ON f.departure_airport = orig.airport_code
  JOIN airport dest ON f.arrival_airport = dest.airport_code
  JOIN aircraft ac ON f.aircraft_code = ac.code
  JOIN booking_leg bl ON f.flight_id = bl.flight_id
  JOIN booking b ON bl.booking_id = b.booking_id
  WHERE f.scheduled_departure >= '2024-07-01 00:00:00+00' 
    AND f.scheduled_departure < '2024-07-04 00:00:00+00'
  GROUP BY orig.airport_code, dest.airport_code, ac.model
  HAVING count(DISTINCT f.flight_id) >= 3
  ORDER BY total_revenue DESC
  LIMIT 50;
  ```

#### **HQ06: Chained Multi-Stage CTEs (Airport Hub Centrality & Network Degree)**
- **Strain Dimension**: Composes 3 separate analytical CTEs aggregating 112,000+ flights (departures, arrivals, unique route destinations), joining back to `airport` metadata to calculate a composite centrality metric. Tests ORM's ability to cleanly express multi-stage CTE graphs.
- **Reference SQL**:
  ```sql
  WITH flight_volumes AS (
      SELECT departure_airport AS airport_code,
             count(*) AS departures_count,
             round(avg(EXTRACT(EPOCH FROM (actual_departure - scheduled_departure)) / 60)::numeric, 2) AS avg_dep_delay
      FROM flight
      WHERE scheduled_departure >= '2024-06-01 00:00:00+00' AND scheduled_departure < '2024-07-01 00:00:00+00'
        AND actual_departure IS NOT NULL
      GROUP BY departure_airport
  ),
  arrival_volumes AS (
      SELECT arrival_airport AS airport_code,
             count(*) AS arrivals_count,
             round(avg(EXTRACT(EPOCH FROM (actual_arrival - scheduled_arrival)) / 60)::numeric, 2) AS avg_arr_delay
      FROM flight
      WHERE scheduled_arrival >= '2024-06-01 00:00:00+00' AND scheduled_arrival < '2024-07-01 00:00:00+00'
        AND actual_arrival IS NOT NULL
      GROUP BY arrival_airport
  ),
  route_connectivity AS (
      SELECT departure_airport AS airport_code,
             count(DISTINCT arrival_airport) AS unique_destinations,
             count(DISTINCT aircraft_code) AS fleet_diversity
      FROM flight
      WHERE scheduled_departure >= '2024-06-01 00:00:00+00' AND scheduled_departure < '2024-07-01 00:00:00+00'
      GROUP BY departure_airport
  )
  SELECT a.airport_code,
         a.airport_name,
         a.city,
         coalesce(fv.departures_count, 0) AS total_departures,
         coalesce(av.arrivals_count, 0) AS total_arrivals,
         coalesce(rc.unique_destinations, 0) AS unique_destinations,
         coalesce(rc.fleet_diversity, 0) AS fleet_diversity,
         coalesce(fv.avg_dep_delay, 0) AS avg_dep_delay,
         coalesce(av.avg_arr_delay, 0) AS avg_arr_delay,
         round(
             (coalesce(fv.departures_count, 0) + coalesce(av.arrivals_count, 0)) * 
             (1.0 + coalesce(rc.unique_destinations, 0) / 100.0) / 
             (1.0 + greatest(coalesce(fv.avg_dep_delay, 0), 0) / 10.0), 
             2
         ) AS hub_centrality_score
  FROM airport a
  JOIN flight_volumes fv ON a.airport_code = fv.airport_code
  JOIN arrival_volumes av ON a.airport_code = av.airport_code
  JOIN route_connectivity rc ON a.airport_code = rc.airport_code
  ORDER BY hub_centrality_score DESC
  LIMIT 50;
  ```

#### **HQ07: Correlated At-Capacity Subquery with Loyalty Tier Cross-Check**
- **Strain Dimension**: Tests correlated scalar subqueries in `SELECT` and `WHERE`, and correlated `EXISTS` checking historical route cancellations.
- **Reference SQL**:
  ```sql
  SELECT f.flight_id,
         f.flight_no,
         f.departure_airport,
         f.arrival_airport,
         f.scheduled_departure,
         ac.model AS aircraft_model,
         ac.range AS aircraft_range,
         (SELECT count(*) 
          FROM booking_leg bl 
          WHERE bl.flight_id = f.flight_id) AS seats_booked,
         (SELECT count(*)
          FROM booking_leg bl
          JOIN passenger p ON bl.booking_id = p.booking_id
          JOIN account a ON p.account_id = a.account_id
          JOIN frequent_flyer ff ON a.frequent_flyer_id = ff.frequent_flyer_id
          WHERE bl.flight_id = f.flight_id AND ff.level >= 3) AS elite_flyer_count
  FROM flight f
  JOIN aircraft ac ON f.aircraft_code = ac.code
  WHERE f.scheduled_departure >= '2024-07-01 00:00:00+00'
    AND f.scheduled_departure < '2024-07-03 00:00:00+00'
    AND ac.class >= 2
    AND (
        SELECT count(*) 
        FROM booking_leg bl 
        WHERE bl.flight_id = f.flight_id
    ) > 40
    AND EXISTS (
        SELECT 1 
        FROM flight route_f 
        WHERE route_f.departure_airport = f.departure_airport 
          AND route_f.arrival_airport = f.arrival_airport 
          AND route_f.status = 'Canceled'
          AND route_f.scheduled_departure >= '2024-06-01 00:00:00+00'
    )
  ORDER BY seats_booked DESC
  LIMIT 100;
  ```

---

### Category IV: Recursive Graph Traversal & Window Analytics (HQ08–HQ10)

#### **HQ08: Recursive Multi-Hop Flight Connection Graph Search (1- to 3-Hop Paths)**
- **Strain Dimension**: Traverses the live flight network using a recursive CTE to find 1-, 2-, and 3-hop connecting flights from 'JFK' to 'ORD' with layovers between 60m and 360m, cycle detection, and journey accumulation.
- **Reference SQL**:
  ```sql
  WITH RECURSIVE flight_paths AS (
      -- Base case: direct flights from JFK
      SELECT f.flight_id,
             f.departure_airport::text AS departure_airport,
             f.arrival_airport::text AS arrival_airport,
             f.scheduled_departure,
             f.scheduled_arrival,
             1 AS hops,
             ARRAY[f.departure_airport::text, f.arrival_airport::text] AS route_airports,
             ARRAY[f.flight_id] AS route_flights,
             f.scheduled_departure AS journey_start,
             f.scheduled_arrival AS journey_end,
             (EXTRACT(EPOCH FROM (f.scheduled_arrival - f.scheduled_departure)) / 60)::numeric(10,2) AS total_flight_minutes
      FROM flight f
      WHERE f.departure_airport = 'JFK'
        AND f.scheduled_departure >= '2024-07-05 00:00:00+00'
        AND f.scheduled_departure < '2024-07-06 00:00:00+00'

      UNION ALL

      -- Recursive case: connecting flights
      SELECT next_f.flight_id,
             fp.departure_airport,
             next_f.arrival_airport::text,
             next_f.scheduled_departure,
             next_f.scheduled_arrival,
             fp.hops + 1,
             fp.route_airports || next_f.arrival_airport::text,
             fp.route_flights || next_f.flight_id,
             fp.journey_start,
             next_f.scheduled_arrival,
             (fp.total_flight_minutes + (EXTRACT(EPOCH FROM (next_f.scheduled_arrival - next_f.scheduled_departure)) / 60))::numeric(10,2)
      FROM flight_paths fp
      JOIN flight next_f ON fp.arrival_airport = next_f.departure_airport
      WHERE fp.hops < 3
        AND next_f.scheduled_departure >= fp.scheduled_arrival + INTERVAL '60 minutes'
        AND next_f.scheduled_departure <= fp.scheduled_arrival + INTERVAL '360 minutes'
        AND NOT (next_f.arrival_airport::text = ANY(fp.route_airports))
  )
  SELECT hops,
         array_to_string(route_airports, ' -> ') AS route,
         journey_start,
         journey_end,
         (EXTRACT(EPOCH FROM (journey_end - journey_start)) / 60)::numeric(10,2) AS total_elapsed_minutes,
         total_flight_minutes
  FROM flight_paths
  WHERE arrival_airport = 'ORD'
  ORDER BY hops ASC, total_elapsed_minutes ASC
  LIMIT 25;
  ```

#### **HQ09: Multi-Window Statistical Delay Dispersion & Cascades**
- **Strain Dimension**: Computes 4 advanced window functions simultaneously: rolling 5-flight moving average delay (`ROWS BETWEEN 4 PRECEDING`), delta delay from prior flight (`LAG`), rolling 10-flight standard deviation (`STDDEV_SAMP`), and severity rank (`DENSE_RANK`).
- **Reference SQL**:
  ```sql
  WITH flight_delays AS (
      SELECT flight_id,
             flight_no,
             departure_airport,
             arrival_airport,
             scheduled_departure,
             actual_departure,
             round((EXTRACT(EPOCH FROM (actual_departure - scheduled_departure)) / 60)::numeric, 2) AS delay_minutes
      FROM flight
      WHERE departure_airport = 'ORD'
        AND actual_departure IS NOT NULL
        AND scheduled_departure >= '2024-06-01 00:00:00+00'
        AND scheduled_departure < '2024-07-01 00:00:00+00'
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
         ), 2) AS rolling_avg_delay_5,
         delay_minutes - lag(delay_minutes, 1) OVER (
             PARTITION BY departure_airport, arrival_airport 
             ORDER BY scheduled_departure
         ) AS delay_diff_prev,
         round(coalesce(stddev_samp(delay_minutes) OVER (
             PARTITION BY departure_airport, arrival_airport 
             ORDER BY scheduled_departure 
             ROWS BETWEEN 9 PRECEDING AND CURRENT ROW
         ), 0), 2) AS rolling_stddev_10,
         dense_rank() OVER (
             PARTITION BY departure_airport, arrival_airport 
             ORDER BY delay_minutes DESC
         ) AS severity_rank
  FROM flight_delays
  ORDER BY departure_airport, arrival_airport, scheduled_departure
  LIMIT 5000;
  ```

#### **HQ10: High-Throughput Keyset (Cursor) Pagination over Composite Tuple Under Concurrency**
- **Strain Dimension**: Fetches page of 50 flights using deterministic composite cursor `(scheduled_departure, flight_id)` across 680,000 rows with 50 concurrent requests.
- **Reference SQL**:
  ```sql
  SELECT flight_id, flight_no, departure_airport, arrival_airport, scheduled_departure, status
  FROM flight
  WHERE (scheduled_departure, flight_id) > ('2024-07-15 12:00:00+00', 10500)
  ORDER BY scheduled_departure ASC, flight_id ASC
  LIMIT 50;
  ```

---

### Category V: Dynamic Query Composition & Bulk Ingestion (HQ11–HQ13)

#### **HQ11: High-Dimensional Dynamic Faceted Flight Search Engine (10 Optional Predicates)**
- **Strain Dimension**: Tests typed dynamic query compilation with 10 optional filters (sets, date ranges, numeric ranges, hour extraction, dynamic sort, and cursor pagination). All filters must be conditionally composed without SQL injection or string concatenation.
- **Reference SQL**:
  ```sql
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
  FROM flight f
  JOIN aircraft ac ON f.aircraft_code = ac.code
  WHERE f.departure_airport IN ('JFK', 'BOS', 'EWR')
    AND f.arrival_airport IN ('LAX', 'SFO', 'SEA')
    AND f.scheduled_departure >= '2024-07-01 00:00:00+00'
    AND f.scheduled_departure <= '2024-07-15 23:59:59+00'
    AND ac.class IN (1, 2, 3)
    AND ac.range >= 2000
    AND f.status IN ('On time', 'Delayed')
    AND EXTRACT(HOUR FROM f.scheduled_departure) BETWEEN 6 AND 21
    AND (f.scheduled_departure, f.flight_id) > ('2024-07-01 06:00:00+00', 500)
  ORDER BY f.scheduled_departure ASC, f.flight_id ASC
  LIMIT 100;
  ```

#### **HQ12: High-Volume Batch Upsert (2,500 Records with Conflict Resolution)**
- **Strain Dimension**: Ingests / upserts a batch of 2,500 flight status updates in a single atomic statement using `INSERT ... VALUES (...) ON CONFLICT (flight_id) DO UPDATE SET ... WHERE ...`. Tests parameter binding allocation, AST statement size limits, and bulk execution throughput.
- **Reference SQL**:
  ```sql
  INSERT INTO flight_status_update (flight_id, status, actual_departure, actual_arrival, update_ts, version)
  VALUES 
      (1, 'Departed', '2024-07-01 08:05:00+00', '2024-07-01 11:15:00+00', clock_timestamp(), 1),
      -- ... 2,500 rows
  ON CONFLICT (flight_id) DO UPDATE SET
      status = EXCLUDED.status,
      actual_departure = EXCLUDED.actual_departure,
      actual_arrival = EXCLUDED.actual_arrival,
      update_ts = EXCLUDED.update_ts,
      version = flight_status_update.version + 1;
  ```

#### **HQ13: Optimistic Concurrency Bulk Fare & Status Adjustment**
- **Strain Dimension**: Conditional multi-row UPDATE with version incrementing: Updates flight status for matching flight IDs while verifying `version = version + 1`. Fails if version mismatch occurs.
- **Reference SQL**:
  ```sql
  UPDATE flight
  SET status = 'Boarding',
      version = version + 1,
      update_ts = clock_timestamp()
  WHERE flight_id BETWEEN 1000 AND 1050
    AND version = 1
  RETURNING flight_id, version;
  ```

---

### Category VI: Concurrency Contention, Transactions & Multi-Modal Search (HQ14–HQ16)

#### **HQ14: High-Concurrency Seat Inventory Allocation Under Contention ($C=50, 100$)**
- **Strain Dimension**: 50–100 concurrent workers competing to reserve the last remaining seats on constrained flights. Measures connection pool exhaustion, tail latency ($p_{99}, p_{99.9}$), lock wait timeouts, and transaction retry overhead under heavy lock contention.
- **Execution Pattern**:
  ```sql
  BEGIN;
  SELECT flight_id, seat_no, version
  FROM flight_seat_inventory
  WHERE flight_id = 101 AND status = 'AVAILABLE'
  LIMIT 1
  FOR UPDATE;

  UPDATE flight_seat_inventory
  SET status = 'RESERVED',
      passenger_name = 'Test Concurrent Flyer',
      reserved_at = clock_timestamp(),
      version = version + 1
  WHERE flight_id = 101 AND seat_no = :seat_no AND version = :version;
  COMMIT;
  ```

#### **HQ15: Distributed Financial / Points Transfer with Serialization Retry**
- **Strain Dimension**: Executes a point transfer between two frequent flyer accounts under `SERIALIZABLE` isolation, catching error code `40001` (`serialization_failure`) and retrying with exponential backoff.
- **Execution Pattern**:
  ```sql
  BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
  UPDATE frequent_flyer SET award_points = award_points - 500 WHERE frequent_flyer_id = 1001;
  UPDATE frequent_flyer SET award_points = award_points + 500 WHERE frequent_flyer_id = 1002;
  COMMIT;
  -- On SQLSTATE 40001: retry with exponential backoff (up to 5 retries).
  ```

#### **HQ16: Multi-Modal Hybrid Vector Similarity + BM25 Full-Text Search with RRF Reranking**
- **Strain Dimension**: Combines 384-dimensional pgvector cosine distance over `embedding` (HNSW) with BM25 full-text search over `search_tsv` (GIN), joined with operational flight statistics, reranked via Reciprocal Rank Fusion ($k=60$).
- **Reference SQL**:
  ```sql
  WITH text_ranking AS (
      SELECT airport_code, 
             ROW_NUMBER() OVER (ORDER BY ts_rank_cd(search_tsv, plainto_tsquery('english', 'London Heathrow international hub')) DESC) AS rank_text
      FROM airport
      WHERE search_tsv @@ plainto_tsquery('english', 'London Heathrow international hub')
      LIMIT 25
  ),
  vector_ranking AS (
      SELECT airport_code, 
             ROW_NUMBER() OVER (ORDER BY (embedding <=> (SELECT embedding FROM airport WHERE airport_code = 'LHR')) ASC) AS rank_vec
      FROM airport
      LIMIT 25
  ),
  airport_stats AS (
      SELECT departure_airport AS airport_code,
             count(*) AS active_flights_count
      FROM flight
      WHERE scheduled_departure >= '2024-07-01 00:00:00+00' AND scheduled_departure < '2024-07-08 00:00:00+00'
      GROUP BY departure_airport
  )
  SELECT COALESCE(t.airport_code, v.airport_code) AS airport_code,
         a.airport_name, 
         a.city,
         COALESCE(ast.active_flights_count, 0) AS active_flights_count,
         round((COALESCE(1.0 / (60 + t.rank_text), 0.0) + COALESCE(1.0 / (60 + v.rank_vec), 0.0))::numeric, 5) AS rrf_score
  FROM text_ranking t
  FULL OUTER JOIN vector_ranking v ON t.airport_code = v.airport_code
  JOIN airport a ON a.airport_code = COALESCE(t.airport_code, v.airport_code)
  LEFT JOIN airport_stats ast ON ast.airport_code = COALESCE(t.airport_code, v.airport_code)
  ORDER BY rrf_score DESC
  LIMIT 25;
  ```

---

## 4. Quantitative Expressiveness & Ergonomics Metrics

For each ORM implementing HQ01–HQ16:

1. **Lines of Code (LoC) & AST Token Count**:
   - Total source lines of code excluding comments and blank lines (measured with `tokei` / `scc`).
   - Token count of query definitions.
2. **Unique Operator & Combinator Count**:
   - Count of domain-specific symbols and combinators introduced by the ORM (e.g., `^.`, `?.`, `==.`, `val_`, `just`, `unSqlBackendKey`).
   - **Target**: Clean ORMs require fewer than 5 non-standard operators.
3. **Schema Change Blast Radius**:
   - Controlled experiment: Add one nullable column `flight_category VARCHAR(32)` to the `flight` table.
   - Count the number of files and lines of code that must be added, deleted, or modified across the project for the application to compile cleanly.

---

## 5. The Deliberate Mistake Suite (Compiler Error UX Benchmark)

A test suite containing **10 intentional compiler failure cases** designed to measure type-safety diagnostic quality:

| Test ID | Mistake Scenario | Description |
| :--- | :--- | :--- |
| **E01** | Type Mismatch in Equality | Comparing `Maybe Text` to `Text`, or `Int` to `Text`. |
| **E02** | Type Mismatch in Join | Joining `flight_id` (Flight key) with `passenger_id` (Passenger key). |
| **E03** | Missing GROUP BY Column | Selecting a non-aggregated column omitted from the `GROUP BY` clause. |
| **E04** | IO / Effect Escape | Attempting to run arbitrary `IO` / side-effects inside a pure transaction block. |
| **E05** | Nullability Constraint Violation | Assigning `Nothing`/null to a non-nullable table column. |
| **E06** | Unknown Column Selection | Typo in column selection (e.g. `flight_noo`). |
| **E07** | Window Function in WHERE | Using `ROW_NUMBER()` or window aggregate inside a `WHERE` clause. |
| **E08** | Dangling Join Variable | Referencing an unbound relation or dangling table alias. |
| **E09** | Mutation of Immutable PK | Attempting to update a Primary Key column in a partial changeset. |
| **E10** | Inner Query Scope Leakage | Referencing an inner subquery column alias outside its projected scope. |

### Diagnostic Scoring Criteria:
- **Error Line Count**: Lines of diagnostic output emitted by the compiler (fewer concise lines preferred).
- **Zero Internal Type Leakage**: Scored **PASS** if the error mentions only user domain types (e.g., `Flight`, `Text`); scored **FAIL** if it leaks internal framework plumbing (e.g., `Default Unpackspec`, `QGenExpr`, `ApplyBindings`, `ToSql`).

---

## 6. Runtime Performance & Concurrency Metrics

Under standardized load testing:
1. **Query Execution Time**: $p_{50}$, $p_{90}$, $p_{95}$, $p_{99}$, and max latency across measurement iterations.
2. **Hydration Throughput**: Deserialization speed in rows/second and MB/second.
3. **CPU Utilization**: Process user-space CPU time and kernel CPU time per query batch.
4. **Heap Allocation & GC Pressure**:
   - Total megabytes allocated during the run.
   - Peak resident memory (Max RSS).
   - GC pause count (minor vs major collections) and cumulative GC pause duration.
5. **Concurrency & Throughput**:
   - Throughput (Requests / Queries per second) at concurrency levels $C \in \{1, 10, 50, 100\}$.
   - Tail latency degradation ($p_{99}, p_{99.9}$) from $C=1$ to $C=100$.
