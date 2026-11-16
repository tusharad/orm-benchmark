# Postgres Air Heavyweight ORM Benchmark Combined Report

> **Total Evaluated ORMs**: 25  
> **Target Database**: PostgreSQL 17 (`postgres_air`, 78+ Million Rows)  
> **Host**: Docker `localhost:5434`  
> **Evaluated Stress Dimensions**: Massive Deserialization & GC Pressure, Deep Entity Trees (N+1 Prevention), Multi-Table Analytical Ledgers, Chained & Recursive CTEs, Advanced Multi-Window Analytics, Dynamic Query DSL Composition, High-Volume Upserts, Concurrency Contention ($C=100$), Quantitative Ergonomics, and Compiler Error UX.

---

## 1. Overall Executive Leaderboard

| Rank | ORM | Language | Overall Score | Passed (HQ01–16) | Avg p95 Latency | Peak RPS ($C=50$) | Hydration Speed | Max Heap RSS | Blast Radius | Compiler UX |
| :---: | :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| 1 | **sqlc** | Go | **95.8** | 16/16 | 58.80 ms | 32340 ops/s | 1518142 rows/s | 25.12 MB | 1 lines | 10/10 |
| 2 | **diesel** | Rust | **86.0** | 16/16 | 59.10 ms | 266 ops/s | 1373304 rows/s | 33.33 MB | 3 lines | 10/10 |
| 3 | **Dapper** | C# / .NET 8 | **84.1** | 16/16 | 62.67 ms | 264 ops/s | 1279038 rows/s | 87.27 MB | 1 lines | 10/10 |
| 4 | **efcore** | C# / .NET 8 | **83.8** | 16/16 | 68.51 ms | 260 ops/s | 1391131 rows/s | 139.80 MB | 1 lines | 10/10 |
| 5 | **sea-orm** | Rust | **82.2** | 16/16 | 66.15 ms | 272 ops/s | 1235677 rows/s | 34.08 MB | 1 lines | 10/10 |
| 6 | **ecto** | Elixir | **80.5** | 16/16 | 58.24 ms | 29412 ops/s | 354070 rows/s | 83.06 MB | 1 lines | 10/10 |
| 7 | **jOOQ** | Java | **78.9** | 16/16 | 57.71 ms | 9739 ops/s | 454966 rows/s | 149.00 MB | 1 lines | 10/10 |
| 8 | **gorm** | Go | **77.2** | 16/16 | 58.50 ms | 256 ops/s | 712657 rows/s | 25.37 MB | 1 lines | 10/10 |
| 9 | **ent** | Go | **74.8** | 16/16 | 61.36 ms | 246 ops/s | 570841 rows/s | 25.12 MB | 1 lines | 10/10 |
| 10 | **hibernate-orm** | Java | **74.5** | 16/16 | 62.66 ms | 256 ops/s | 564130 rows/s | 15.00 MB | 1 lines | 10/10 |
| 11 | **sqlalchemy** | Python | **74.1** | 16/16 | 72.57 ms | 5718 ops/s | 279239 rows/s | 92.50 MB | 1 lines | 10/10 |
| 12 | **mikro-orm** | TypeScript | **73.5** | 16/16 | 58.19 ms | 3302 ops/s | 182594 rows/s | 239.52 MB | 1 lines | 10/10 |
| 13 | **drizzle-orm** | TypeScript | **72.5** | 16/16 | 64.45 ms | 242 ops/s | 498613 rows/s | 184.58 MB | 4 lines | 10/10 |
| 14 | **typeorm** | TypeScript | **72.3** | 16/16 | 55.99 ms | 235 ops/s | 385422 rows/s | 71.55 MB | 1 lines | 10/10 |
| 15 | **hasql** | Haskell | **69.3** | 16/16 | 65.83 ms | 277 ops/s | 199025 rows/s | 13.03 MB | 1 lines | 10/10 |
| 16 | **ihp** | Haskell | **68.2** | 16/16 | 70.41 ms | 361 ops/s | 144224 rows/s | 76.00 MB | 1 lines | 10/10 |
| 17 | **orville** | Haskell | **66.4** | 16/16 | 73.71 ms | 247 ops/s | 99705 rows/s | 38.79 MB | 1 lines | 10/10 |
| 18 | **persistent** | Haskell | **65.9** | 16/16 | 77.55 ms | 252 ops/s | 103221 rows/s | 21.03 MB | 1 lines | 10/10 |
| 19 | **prisma** | TypeScript | **65.5** | 16/16 | 83.54 ms | 264 ops/s | 208122 rows/s | 36.71 MB | 1 lines | 10/10 |
| 20 | **haskell-opaleye** | Haskell | **65.0** | 16/16 | 80.38 ms | 254 ops/s | 101544 rows/s | 26.54 MB | 2 lines | 10/10 |
| 21 | **beam** | Haskell | **64.7** | 16/16 | 77.50 ms | 241 ops/s | 113504 rows/s | 22.39 MB | 6 lines | 10/10 |
| 22 | **esqueleto** | Haskell | **64.1** | 16/16 | 82.16 ms | 250 ops/s | 85377 rows/s | 25.22 MB | 2 lines | 10/10 |
| 23 | **rails** | Ruby | **64.0** | 16/16 | 85.34 ms | 247 ops/s | 89792 rows/s | 150.00 MB | 1 lines | 10/10 |
| 24 | **rel8** | Haskell | **56.2** | 16/16 | 132.32 ms | 254 ops/s | 122678 rows/s | 18.75 MB | 1 lines | 10/10 |
| 25 | **squeal** | Haskell | **45.3** | 16/16 | 187.03 ms | 258 ops/s | 15271 rows/s | 25.17 MB | 1 lines | 10/10 |

---

## 2. The 16 Heavyweight Canonical Queries Scorecard

Status: ✅ = Native Typed Pass, ⚠️ = Workaround / Dynamic Fallback, ❌ = Failed / Unsupported, ⏳ = Pending.

| Query ID | Description | sqlc | diesel | Dapper | efcore | sea-orm | ecto | jOOQ | gorm | ent | hibernate-orm | sqlalchemy | mikro-orm | drizzle-orm | typeorm | hasql | ihp | orville | persistent | prisma | haskell-opaleye | beam | esqueleto | rails | rel8 | squeal |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **HQ01** | Massive Entity Deserialization (10k Wide Rows) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **HQ02** | Wide Multi-Join Composite Hydration (5k Joined Rows) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **HQ03** | 4-Level Deep Entity Tree (Flight->Legs->Booking->Pass) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **HQ04** | Account Relationship Graph with Optional Sub-Entities | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **HQ05** | Fleet & Route Profitability Ledger (5 Tables, 400k+ Rows) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **HQ06** | Chained Multi-Stage CTEs (Hub Centrality & Degree) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **HQ07** | Correlated At-Capacity Subquery + Loyalty Cross-Check | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **HQ08** | Recursive Multi-Hop Flight Connection Graph (1-3 Hops) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **HQ09** | Multi-Window Statistical Delay Dispersion & Cascades | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **HQ10** | Keyset (Cursor) Pagination over Composite Key Under Load | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **HQ11** | High-Dimensional Dynamic Faceted Flight Search Engine | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **HQ12** | High-Volume Batch Upsert (2,500 Records ON CONFLICT) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **HQ13** | Optimistic Concurrency Bulk Fare & Status Adjustment | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **HQ14** | High-Concurrency Seat Allocation Under Contention (C=100) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **HQ15** | Distributed Financial / Points Transfer with 40001 Retry | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **HQ16** | Multi-Modal Hybrid Vector Similarity + BM25 RRF Search | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## 3. Large-Scale Hydration, Memory & GC Pressure Profile

Measures decoding overhead, heap allocation rate, and garbage collection pressure when deserializing large datasets into native language records/structs.

| ORM | HQ01 10k Rows (p95 ms) | HQ02 5k Joined (p95 ms) | Hydration Throughput | Total Allocated (MB) | Peak Heap RSS (MB) | Minor GC Pauses | Major GC Pauses | Total GC Pause (ms) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **sqlc** | 9.14 ms | 6.74 ms | 1518142 rows/s | 521.84 MB | 25.12 MB | 187 | 0 | 6.18 ms |
| **diesel** | 7.64 ms | 8.24 ms | 1373304 rows/s | 420.00 MB | 33.33 MB | 0 | 0 | 0.00 ms |
| **Dapper** | 23.17 ms | 19.56 ms | 1279038 rows/s | 211.78 MB | 87.27 MB | 41 | 7 | 0.00 ms |
| **efcore** | 26.61 ms | 17.08 ms | 1391131 rows/s | 281.27 MB | 139.80 MB | 59 | 8 | 0.00 ms |
| **sea-orm** | 8.71 ms | 8.60 ms | 1235677 rows/s | 350.00 MB | 34.08 MB | 0 | 0 | 0.00 ms |
| **ecto** | 32.58 ms | 11.94 ms | 354070 rows/s | 1994.53 MB | 83.06 MB | 13046 | 0 | 0.00 ms |
| **jOOQ** | 40.49 ms | 13.25 ms | 454966 rows/s | 256.00 MB | 149.00 MB | 11 | 2 | 30.00 ms |
| **gorm** | 15.09 ms | 11.29 ms | 712657 rows/s | 410.38 MB | 25.37 MB | 171 | 0 | 8.10 ms |
| **ent** | 18.16 ms | 12.88 ms | 570841 rows/s | 426.71 MB | 25.12 MB | 153 | 0 | 7.45 ms |
| **hibernate-orm** | 30.38 ms | 28.99 ms | 564130 rows/s | 256.00 MB | 15.00 MB | 9 | 5 | 49.00 ms |
| **sqlalchemy** | 42.18 ms | 11.82 ms | 279239 rows/s | 450.00 MB | 92.50 MB | 1162 | 8 | 12.50 ms |
| **mikro-orm** | 68.78 ms | 9.11 ms | 182594 rows/s | 512.00 MB | 239.52 MB | 0 | 0 | 0.00 ms |
| **drizzle-orm** | 23.39 ms | 13.30 ms | 498613 rows/s | 650.00 MB | 184.58 MB | 0 | 0 | 0.00 ms |
| **typeorm** | 41.69 ms | 9.18 ms | 385422 rows/s | 512.00 MB | 71.55 MB | 0 | 0 | 0.00 ms |
| **hasql** | 60.44 ms | 38.75 ms | 199025 rows/s | 1793.68 MB | 13.03 MB | 349 | 55 | 321.90 ms |
| **ihp** | 75.64 ms | 54.03 ms | 144224 rows/s | 1850.00 MB | 76.00 MB | 412 | 14 | 62.50 ms |
| **orville** | 109.73 ms | 46.59 ms | 99705 rows/s | 7268.27 MB | 38.79 MB | 1452 | 726 | 590.28 ms |
| **persistent** | 105.33 ms | 158.59 ms | 103221 rows/s | 9919.74 MB | 21.03 MB | 2061 | 1030 | 511.27 ms |
| **prisma** | 52.00 ms | 11.71 ms | 208122 rows/s | 512.00 MB | 36.71 MB | 0 | 0 | 0.00 ms |
| **haskell-opaleye** | 105.29 ms | 147.00 ms | 101544 rows/s | 15233.18 MB | 26.54 MB | 3181 | 1590 | 798.34 ms |
| **beam** | 96.05 ms | 102.37 ms | 113504 rows/s | 14096.83 MB | 22.39 MB | 1537 | 1538 | 779.31 ms |
| **esqueleto** | 129.78 ms | 170.28 ms | 85377 rows/s | 11988.07 MB | 25.22 MB | 1284 | 1284 | 613.37 ms |
| **rails** | 115.09 ms | 27.97 ms | 89792 rows/s | 512.00 MB | 150.00 MB | 0 | 0 | 0.00 ms |
| **rel8** | 83.50 ms | 868.39 ms | 122678 rows/s | 3696.52 MB | 18.75 MB | 523 | 62 | 535.32 ms |
| **squeal** | 668.66 ms | 1191.14 ms | 15271 rows/s | 4910.59 MB | 25.17 MB | 695 | 60 | 1470.17 ms |

---

## 4. Application-Level Concurrency & Scalability Ladder

Measures throughput and tail latencies across increasing concurrency levels ($C \in \{1, 10, 50, 100\}$) on a standardized 20-connection pool.

| ORM | $C=1$ (RPS / p99) | $C=10$ (RPS / p99) | $C=50$ (RPS / p99) | $C=100$ (RPS / p99) | HQ14 Contention RPS | HQ14 Tail p99.9 | Contention Falloff % |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **sqlc** | 8854 / 0.19ms | 26605 / 3.76ms | 25206 / 5.54ms | 32340 / 3.55ms | 3745 ops/s | 26.63 ms | - |
| **diesel** | 87 / 28.02ms | 266 / 66.00ms | 259 / 110.00ms | 256 / 127.07ms | 256 ops/s | 0.86 ms | - |
| **Dapper** | 79 / 14.94ms | 232 / 37.75ms | 254 / 136.99ms | 264 / 121.65ms | 3424 ops/s | 28.69 ms | - |
| **efcore** | 83 / 14.14ms | 226 / 32.30ms | 260 / 30.05ms | 258 / 599.85ms | 2266 ops/s | 42.06 ms | - |
| **sea-orm** | 83 / 14.21ms | 272 / 69.28ms | 266 / 238.55ms | 253 / 479.06ms | 253 ops/s | 0.92 ms | - |
| **ecto** | 3333 / 0.49ms | 20000 / 0.78ms | 27778 / 2.60ms | 29412 / 4.29ms | 763 ops/s | 2.15 ms | - |
| **jOOQ** | 2451 / 0.85ms | 2654 / 16.57ms | 9263 / 27.79ms | 9739 / 39.18ms | - | 0.47 ms | - |
| **gorm** | 87 / 13.89ms | 261 / 57.44ms | 256 / 557.43ms | 252 / 786.58ms | 3563 ops/s | 27.91 ms | - |
| **ent** | 79 / 15.08ms | 250 / 72.31ms | 246 / 674.30ms | 240 / 821.97ms | 4111 ops/s | 24.02 ms | - |
| **hibernate-orm** | 81 / 14.02ms | 236 / 84.17ms | 256 / 1023.84ms | 243 / 3075.00ms | - | 0.85 ms | - |
| **sqlalchemy** | 2595 / 0.94ms | 4581 / 14.30ms | 4957 / 41.93ms | 5718 / 55.19ms | 5718 ops/s | 0.81 ms | - |
| **mikro-orm** | 1775 / 0.93ms | 2871 / 17.91ms | 3302 / 21.19ms | 3118 / 38.43ms | 3118 ops/s | 13.45 ms | - |
| **drizzle-orm** | 85 / 14.03ms | 242 / 64.19ms | 238 / 245.98ms | 225 / 504.79ms | 225 ops/s | 1.33 ms | - |
| **typeorm** | 70 / 25.38ms | 235 / 68.35ms | 217 / 290.70ms | 225 / 570.70ms | 225 ops/s | 0.62 ms | - |
| **hasql** | 83 / 13.64ms | 277 / 54.93ms | 263 / 108.12ms | 264 / 119.94ms | 3548 ops/s | 0.78 ms | - |
| **ihp** | 107 / 15.18ms | 361 / 56.38ms | 360 / 179.04ms | 351 / 327.38ms | 9565 ops/s | 0.54 ms | - |
| **orville** | 66 / 15.25ms | 210 / 15.25ms | 247 / 15.25ms | 245 / 15.25ms | - | 1.16 ms | - |
| **persistent** | 74 / 13.91ms | 252 / 13.91ms | 251 / 13.91ms | 245 / 13.91ms | - | 0.96 ms | - |
| **prisma** | 79 / 14.08ms | 264 / 64.82ms | 254 / 246.74ms | 247 / 445.36ms | 247 ops/s | 0.82 ms | - |
| **haskell-opaleye** | 76 / 12.77ms | 265 / 12.77ms | 254 / 12.77ms | 251 / 12.77ms | - | 1.00 ms | - |
| **beam** | 78 / 18.60ms | 253 / 22.32ms | 241 / 33.48ms | 234 / 46.50ms | 234 ops/s | 0.50 ms | - |
| **esqueleto** | 73 / 15.18ms | 254 / 19.74ms | 250 / 31.89ms | 244 / 48.59ms | 244 ops/s | 1.07 ms | - |
| **rails** | 78 / 26.93ms | 247 / 71.36ms | 240 / 262.33ms | 228 / 497.99ms | 228 ops/s | 0.66 ms | - |
| **rel8** | 78 / 13.89ms | 254 / 61.84ms | 253 / 109.07ms | 244 / 124.93ms | 244 ops/s | 0.70 ms | - |
| **squeal** | 82 / 13.87ms | 258 / 69.06ms | 251 / 246.23ms | 227 / 511.81ms | 227 ops/s | 0.74 ms | - |

---

## 5. Quantitative Ergonomics & Expressiveness

| ORM | Query LoC (Total HQ01–HQ16) | AST Token Count | Unique DSL Operators | Operator Complexity Score | Schema Blast Radius (Lines changed) | Files Changed |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **sqlc** | 337 | 1680 | 5 | 9 | 1 | 1 |
| **diesel** | 281 | 1690 | 6 | 8.5 | 3 | 1 |
| **Dapper** | 465 | 2100 | 6 | 9.2 | 1 | 1 |
| **efcore** | 460 | 2350 | 8 | 8.8 | 1 | 1 |
| **sea-orm** | 285 | 1720 | 8 | 8.5 | 1 | 1 |
| **ecto** | 275 | 1520 | 5 | 9.0 | 1 | 1 |
| **jOOQ** | 410 | 2200 | 8 | 9.5 | 1 | 1 |
| **gorm** | 463 | 2280 | 6 | 8.9 | 1 | 1 |
| **ent** | 541 | 2250 | 6 | 9 | 1 | 1 |
| **hibernate-orm** | 450 | 2350 | 6 | 9.0 | 1 | 1 |
| **sqlalchemy** | 375 | 2100 | 6 | 9.0 | 1 | 1 |
| **mikro-orm** | 310 | 1850 | 8 | 8.5 | 1 | 1 |
| **drizzle-orm** | 289 | 1740 | 8 | 8 | 4 | 1 |
| **typeorm** | 320 | 1900 | 8 | 8.4 | 1 | 1 |
| **hasql** | 450 | 2100 | 6 | 9.4 | 1 | 1 |
| **ihp** | 410 | 1950 | 6 | 9.3 | 1 | 1 |
| **orville** | 290 | 1650 | 6 | 9.2 | 1 | 1 |
| **persistent** | 280 | 1600 | 6 | 9.1 | 1 | 1 |
| **prisma** | 300 | 1780 | 8 | 8.5 | 1 | 1 |
| **haskell-opaleye** | 280 | 1780 | 7 | 8.5 | 2 | 1 |
| **beam** | 285 | 1820 | 9 | 7.5 | 6 | 1 |
| **esqueleto** | 280 | 1760 | 8 | 8 | 2 | 1 |
| **rails** | 260 | 1540 | 7 | 9.0 | 1 | 1 |
| **rel8** | 275 | 1700 | 8 | 8.5 | 1 | 1 |
| **squeal** | 280 | 1800 | 9 | 8.8 | 1 | 1 |

---

## 6. The Deliberate Mistake Suite (Compiler Error UX)

Scoring: `Lines` = Diagnostic lines emitted by compiler; `Leakage` = **Zero** (mentions only user types) vs **Leaked** (internal library plumbing leaked).

| Mistake Scenario | Metric | **sqlc** | **diesel** | **Dapper** | **efcore** | **sea-orm** | **ecto** | **jOOQ** | **gorm** | **ent** | **hibernate-orm** | **sqlalchemy** | **mikro-orm** | **drizzle-orm** | **typeorm** | **hasql** | **ihp** | **orville** | **persistent** | **prisma** | **haskell-opaleye** | **beam** | **esqueleto** | **rails** | **rel8** | **squeal** |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **E01: Type Mismatch in Equality** | Lines / Leakage | 2 lines / Zero | 63 lines / Zero | 6 lines / Zero | 20 lines / Zero | 36 lines / Zero | 8 lines / Zero | 12 lines / Zero | 2 lines / Zero | 2 lines / Zero | 14 lines / Zero | 4 lines / Zero | 5 lines / Zero | 5 lines / Zero | 5 lines / Zero | 39 lines / Zero | 9 lines / Zero | 7 lines / Zero | 7 lines / Zero | 5 lines / Zero | 7 lines / Zero | 24 lines / Zero | 8 lines / Zero | 3 lines / Zero | 8 lines / Zero | 6 lines / Zero |
| **E02: Key Mismatch in Join** | Lines / Leakage | 2 lines / Zero | 23 lines / Zero | 6 lines / Zero | 20 lines / Zero | 41 lines / Zero | 8 lines / Zero | 12 lines / Zero | 2 lines / Zero | 2 lines / Zero | 15 lines / Zero | 4 lines / Zero | 5 lines / Zero | 5 lines / Zero | 5 lines / Zero | 5 lines / Zero | 9 lines / Zero | 7 lines / Zero | 7 lines / Zero | 5 lines / Zero | 7 lines / Zero | 22 lines / Zero | 9 lines / Zero | 3 lines / Zero | 8 lines / Zero | 6 lines / Zero |
| **E03: Missing GROUP BY Column** | Lines / Leakage | 2 lines / Zero | 25 lines / Zero | 6 lines / Zero | 20 lines / Zero | 43 lines / Zero | 7 lines / Zero | 6 lines / Zero | 2 lines / Zero | 2 lines / Zero | 6 lines / Zero | 5 lines / Zero | 6 lines / Zero | 6 lines / Zero | 6 lines / Zero | 19 lines / Zero | 25 lines / Zero | 6 lines / Zero | 6 lines / Zero | 6 lines / Zero | 6 lines / Zero | 18 lines / Zero | 7 lines / Zero | 3 lines / Zero | 33 lines / Zero | 8 lines / Zero |
| **E04: IO Escape inside Pure Transaction** | Lines / Leakage | 2 lines / Zero | 19 lines / Zero | 6 lines / Zero | 20 lines / Zero | 30 lines / Zero | 3 lines / Zero | 5 lines / Zero | 2 lines / Zero | 2 lines / Zero | 5 lines / Zero | 4 lines / Zero | 4 lines / Zero | 4 lines / Zero | 4 lines / Zero | 39 lines / Zero | 13 lines / Zero | 6 lines / Zero | 6 lines / Zero | 4 lines / Zero | 6 lines / Zero | 12 lines / Zero | 15 lines / Zero | 1 lines / Zero | 15 lines / Zero | 4 lines / Zero |
| **E05: Nullability Constraint Violation** | Lines / Leakage | 2 lines / Zero | 2 lines / Zero | 6 lines / Zero | 20 lines / Zero | 36 lines / Zero | 9 lines / Zero | 4 lines / Zero | 2 lines / Zero | 2 lines / Zero | 4 lines / Zero | 4 lines / Zero | 5 lines / Zero | 5 lines / Zero | 5 lines / Zero | 28 lines / Zero | 12 lines / Zero | 7 lines / Zero | 7 lines / Zero | 5 lines / Zero | 7 lines / Zero | 20 lines / Zero | 7 lines / Zero | 3 lines / Zero | 9 lines / Zero | 6 lines / Zero |
| **E06: Unknown Column Selection** | Lines / Leakage | 2 lines / Zero | 20 lines / Zero | 6 lines / Zero | 20 lines / Zero | 19 lines / Zero | 5 lines / Zero | 6 lines / Zero | 2 lines / Zero | 2 lines / Zero | 6 lines / Zero | 5 lines / Zero | 3 lines / Zero | 3 lines / Zero | 3 lines / Zero | 2 lines / Zero | 26 lines / Zero | 4 lines / Zero | 4 lines / Zero | 3 lines / Zero | 4 lines / Zero | 8 lines / Zero | 3 lines / Zero | 5 lines / Zero | 16 lines / Zero | 5 lines / Zero |
| **E07: Window Function in WHERE Clause** | Lines / Leakage | 2 lines / Zero | 2 lines / Zero | 6 lines / Zero | 20 lines / Zero | 19 lines / Zero | 7 lines / Zero | 20 lines / Zero | 2 lines / Zero | 2 lines / Zero | 6 lines / Zero | 4 lines / Zero | 4 lines / Zero | 4 lines / Zero | 4 lines / Zero | 4 lines / Zero | 8 lines / Zero | 6 lines / Zero | 6 lines / Zero | 4 lines / Zero | 6 lines / Zero | 24 lines / Zero | 2 lines / Zero | 3 lines / Zero | 6 lines / Zero | 5 lines / Zero |
| **E08: Dangling Join / Unbound Table Alias** | Lines / Leakage | 2 lines / Zero | 28 lines / Zero | 6 lines / Zero | 20 lines / Zero | 41 lines / Zero | 5 lines / Zero | 4 lines / Zero | 2 lines / Zero | 2 lines / Zero | 6 lines / Zero | 4 lines / Zero | 5 lines / Zero | 5 lines / Zero | 5 lines / Zero | 31 lines / Zero | 8 lines / Zero | 5 lines / Zero | 5 lines / Zero | 5 lines / Zero | 5 lines / Zero | 14 lines / Zero | 2 lines / Zero | 3 lines / Zero | 2 lines / Zero | 5 lines / Zero |
| **E09: Mutation of Immutable Primary Key** | Lines / Leakage | 2 lines / Zero | 2 lines / Zero | 6 lines / Zero | 20 lines / Zero | 34 lines / Zero | 14 lines / Zero | 4 lines / Zero | 2 lines / Zero | 2 lines / Zero | 4 lines / Zero | 5 lines / Zero | 4 lines / Zero | 4 lines / Zero | 4 lines / Zero | 32 lines / Zero | 12 lines / Zero | 8 lines / Zero | 8 lines / Zero | 4 lines / Zero | 8 lines / Zero | 18 lines / Zero | 11 lines / Zero | 1 lines / Zero | 63 lines / Zero | 6 lines / Zero |
| **E10: Inner Query Scope Leakage** | Lines / Leakage | 2 lines / Zero | 14 lines / Zero | 6 lines / Zero | 20 lines / Zero | 25 lines / Zero | 5 lines / Zero | 6 lines / Zero | 2 lines / Zero | 2 lines / Zero | 6 lines / Zero | 5 lines / Zero | 4 lines / Zero | 4 lines / Zero | 4 lines / Zero | 31 lines / Zero | 2 lines / Zero | 5 lines / Zero | 5 lines / Zero | 4 lines / Zero | 5 lines / Zero | 16 lines / Zero | 2 lines / Zero | 3 lines / Zero | 2 lines / Zero | 5 lines / Zero |

---

## 7. Individual ORM Detailed Breakdown

### SQLC (Go)
- **Framework Version**: Go 1.23 / sqlc v1.31.1
- **Benchmark Timestamp**: 2026-11-15T17:04:16.994326689Z
- **Implementation Path**: `../sqlc/sqlc-postgres-air-bench`

#### Latency Distribution across Heavyweight Canonical Queries:
| Query | Status | p50 (ms) | p95 (ms) | p99 (ms) | LoC | Throughput | Notes |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| HQ01 (Massive Entity Deserialization (10k Wide Rows)) | ✅ | 6.79 | 9.14 | 9.14 | 7 | 1518142 | 10k flight entities hydrated |
| HQ02 (Wide Multi-Join Composite Hydration (5k Joined Rows)) | ✅ | 6.63 | 6.74 | 6.74 | 14 | 732279 | 5k 4-table joined records |
| HQ03 (4-Level Deep Entity Tree (Flight->Legs->Booking->Pass)) | ✅ | 2.47 | 2.65 | 2.65 | 11 | - | 4-level deep graph assembly (0 N+1) |
| HQ04 (Account Relationship Graph with Optional Sub-Entities) | ✅ | 11.38 | 12.04 | 12.04 | 13 | - | Account graph with 7,000 joined records |
| HQ05 (Fleet & Route Profitability Ledger (5 Tables, 400k+ Rows)) | ✅ | 354.55 | 369.28 | 369.28 | 21 | - | 5-table analytical ledger over 410k rows |
| HQ06 (Chained Multi-Stage CTEs (Hub Centrality & Degree)) | ✅ | 87.23 | 89.67 | 89.67 | 45 | - | 3 chained CTEs hub centrality over 112k flights |
| HQ07 (Correlated At-Capacity Subquery + Loyalty Cross-Check) | ✅ | 100.54 | 104.56 | 104.56 | 32 | - | Correlated subqueries in SELECT & WHERE |
| HQ08 (Recursive Multi-Hop Flight Connection Graph (1-3 Hops)) | ✅ | 310.31 | 323.57 | 323.57 | 42 | - | Recursive 1- to 3-hop itinerary graph traversal |
| HQ09 (Multi-Window Statistical Delay Dispersion & Cascades) | ✅ | 5.40 | 5.51 | 5.51 | 35 | - | 4 simultaneous window functions with framing |
| HQ10 (Keyset (Cursor) Pagination over Composite Key Under Load) | ✅ | 0.11 | 0.12 | 0.12 | 7 | - | Composite keyset cursor pagination |
| HQ11 (High-Dimensional Dynamic Faceted Flight Search Engine) | ✅ | 0.24 | 0.26 | 0.26 | 20 | - | Dynamic faceted search with 10 predicates |
| HQ12 (High-Volume Batch Upsert (2,500 Records ON CONFLICT)) | ✅ | 9.21 | 9.38 | 9.38 | 14 | - | sqlc batch upsert 2,500 rows ON CONFLICT |
| HQ13 (Optimistic Concurrency Bulk Fare & Status Adjustment) | ✅ | 0.09 | 0.09 | 0.09 | 8 | - | Optimistic version increment |
| HQ14 (High-Concurrency Seat Allocation Under Contention (C=100)) | ✅ | 0.28 | 0.29 | 26.63 | 16 | 3745 | Concurrent seat reservation with FOR UPDATE |
| HQ15 (Distributed Financial / Points Transfer with 40001 Retry) | ✅ | 0.30 | 0.35 | 0.35 | 24 | - | Serializable points transfer with 40001 retry |
| HQ16 (Multi-Modal Hybrid Vector Similarity + BM25 RRF Search) | ✅ | 6.70 | 7.09 | 7.09 | 28 | - | Hybrid 384-dim HNSW + BM25 RRF search |

#### Deliberate Mistakes Diagnostics Summary:
```text
No diagnostic logs attached.
```

---

### DIESEL (Rust)
- **Framework Version**: 2.4.0
- **Benchmark Timestamp**: 2026-11-14T19:46:05.016950+00:00
- **Implementation Path**: `../diesel/diesel-postgres-air-bench`

#### Latency Distribution across Heavyweight Canonical Queries:
| Query | Status | p50 (ms) | p95 (ms) | p99 (ms) | LoC | Throughput | Notes |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| HQ01 (Massive Entity Deserialization (10k Wide Rows)) | ✅ | 7.28 | 7.64 | 7.64 | 8 | 1373304 | 10k flight entities hydrated |
| HQ02 (Wide Multi-Join Composite Hydration (5k Joined Rows)) | ✅ | 8.07 | 8.24 | 8.24 | 14 | 619848 | 5k 4-table joined records |
| HQ03 (4-Level Deep Entity Tree (Flight->Legs->Booking->Pass)) | ✅ | 3.28 | 3.32 | 3.32 | 22 | 672257 | 4-level deep graph assembly (0 N+1) |
| HQ04 (Account Relationship Graph with Optional Sub-Entities) | ✅ | 12.60 | 12.83 | 12.83 | 26 | - | Account graph with 7,000 joined records |
| HQ05 (Fleet & Route Profitability Ledger (5 Tables, 400k+ Rows)) | ✅ | 350.35 | 356.37 | 356.37 | 22 | - | 5-table analytical ledger over 410k rows |
| HQ06 (Chained Multi-Stage CTEs (Hub Centrality & Degree)) | ✅ | 83.97 | 84.42 | 84.42 | 25 | - | 3 chained CTEs hub centrality over 112k flights |
| HQ07 (Correlated At-Capacity Subquery + Loyalty Cross-Check) | ✅ | 99.33 | 118.51 | 118.51 | 20 | - | Correlated subqueries in SELECT & WHERE |
| HQ08 (Recursive Multi-Hop Flight Connection Graph (1-3 Hops)) | ✅ | 299.98 | 308.31 | 308.31 | 24 | - | Recursive 1- to 3-hop itinerary graph traversal |
| HQ09 (Multi-Window Statistical Delay Dispersion & Cascades) | ✅ | 6.20 | 6.43 | 6.43 | 20 | - | 4 simultaneous window functions with framing |
| HQ10 (Keyset (Cursor) Pagination over Composite Key Under Load) | ✅ | 11.28 | 12.09 | 12.09 | 10 | - | Composite keyset cursor pagination |
| HQ11 (High-Dimensional Dynamic Faceted Flight Search Engine) | ✅ | 7.81 | 8.08 | 8.21 | 28 | - | Dynamic faceted search with 10 predicates |
| HQ12 (High-Volume Batch Upsert (2,500 Records ON CONFLICT)) | ✅ | 11.92 | 13.03 | 13.03 | 12 | - | Diesel on_conflict 2,500 rows batch upsert |
| HQ13 (Optimistic Concurrency Bulk Fare & Status Adjustment) | ✅ | 1.39 | 1.72 | 1.72 | 8 | - | Optimistic version increment |
| HQ14 (High-Concurrency Seat Allocation Under Contention (C=100)) | ✅ | 0.68 | 0.73 | 0.86 | 16 | 256 | Concurrent seat reservation with FOR UPDATE |
| HQ15 (Distributed Financial / Points Transfer with 40001 Retry) | ✅ | 0.67 | 0.74 | 0.74 | 18 | - | Serializable points transfer with 40001 retry |
| HQ16 (Multi-Modal Hybrid Vector Similarity + BM25 RRF Search) | ✅ | 3.04 | 3.17 | 3.17 | 18 | - | Hybrid 384-dim HNSW + BM25 RRF search |

#### Deliberate Mistakes Diagnostics Summary:
```text
No diagnostic logs attached.
```

---

### DAPPER (C# / .NET 8)
- **Framework Version**: 2.1.35
- **Benchmark Timestamp**: 2026-11-15T17:53:01.8521708Z
- **Implementation Path**: `../Dapper/bench`

#### Latency Distribution across Heavyweight Canonical Queries:
| Query | Status | p50 (ms) | p95 (ms) | p99 (ms) | LoC | Throughput | Notes |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| HQ01 (Massive Entity Deserialization (10k Wide Rows)) | ✅ | 22.20 | 23.17 | 23.17 | 11 | 1279038 | 10k flight entities hydrated |
| HQ02 (Wide Multi-Join Composite Hydration (5k Joined Rows)) | ✅ | 18.16 | 19.56 | 19.56 | 27 | 648147 | 5k 4-table joined records |
| HQ03 (4-Level Deep Entity Tree (Flight->Legs->Booking->Pass)) | ✅ | 13.04 | 14.02 | 14.02 | 44 | - | 4-level deep graph assembly (0 N+1) |
| HQ04 (Account Relationship Graph with Optional Sub-Entities) | ✅ | 23.89 | 24.71 | 24.71 | 16 | - | Account graph with 7,000 joined records |
| HQ05 (Fleet & Route Profitability Ledger (5 Tables, 400k+ Rows)) | ✅ | 367.63 | 371.29 | 371.29 | 22 | - | 5-table analytical ledger over 410k rows |
| HQ06 (Chained Multi-Stage CTEs (Hub Centrality & Degree)) | ✅ | 88.58 | 91.15 | 91.15 | 44 | - | 3 chained CTEs hub centrality over 112k flights |
| HQ07 (Correlated At-Capacity Subquery + Loyalty Cross-Check) | ✅ | 104.64 | 105.24 | 105.24 | 32 | - | Correlated subqueries in SELECT & WHERE |
| HQ08 (Recursive Multi-Hop Flight Connection Graph (1-3 Hops)) | ✅ | 304.98 | 305.69 | 305.69 | 45 | - | Recursive 1- to 3-hop itinerary graph traversal |
| HQ09 (Multi-Window Statistical Delay Dispersion & Cascades) | ✅ | 6.27 | 6.40 | 6.40 | 36 | - | 4 simultaneous window functions with framing |
| HQ10 (Keyset (Cursor) Pagination over Composite Key Under Load) | ✅ | 12.74 | 12.83 | 12.83 | 13 | - | Composite keyset cursor pagination |
| HQ11 (High-Dimensional Dynamic Faceted Flight Search Engine) | ✅ | 8.32 | 8.81 | 8.81 | 38 | - | Dynamic faceted search with 10 predicates |
| HQ12 (High-Volume Batch Upsert (2,500 Records ON CONFLICT)) | ✅ | 8.50 | 11.99 | 11.99 | 19 | - | High-volume 2,500 rows batch upsert |
| HQ13 (Optimistic Concurrency Bulk Fare & Status Adjustment) | ✅ | 2.44 | 2.88 | 2.88 | 15 | - | Optimistic version increment |
| HQ14 (High-Concurrency Seat Allocation Under Contention (C=100)) | ✅ | 0.94 | 1.06 | 28.69 | 28 | 3424 | Concurrent seat reservation with FOR UPDATE |
| HQ15 (Distributed Financial / Points Transfer with 40001 Retry) | ✅ | 0.58 | 0.68 | 0.68 | 41 | - | Serializable points transfer with 40001 retry |
| HQ16 (Multi-Modal Hybrid Vector Similarity + BM25 RRF Search) | ✅ | 2.96 | 3.21 | 3.21 | 34 | - | Hybrid 384-dim HNSW + BM25 RRF search |

#### Deliberate Mistakes Diagnostics Summary:
```text
No diagnostic logs attached.
```

---

### EFCORE (C# / .NET 8)
- **Framework Version**: 8.0.11
- **Benchmark Timestamp**: 2026-11-15T04:27:43.8334481Z
- **Implementation Path**: `../efcore/bench`

#### Latency Distribution across Heavyweight Canonical Queries:
| Query | Status | p50 (ms) | p95 (ms) | p99 (ms) | LoC | Throughput | Notes |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| HQ01 (Massive Entity Deserialization (10k Wide Rows)) | ✅ | 21.45 | 26.61 | 26.61 | 4 | 1391131 | 10k flight entities hydrated |
| HQ02 (Wide Multi-Join Composite Hydration (5k Joined Rows)) | ✅ | 15.80 | 17.08 | 17.08 | 17 | 615109 | 5k 4-table joined records |
| HQ03 (4-Level Deep Entity Tree (Flight->Legs->Booking->Pass)) | ✅ | 17.12 | 18.36 | 18.36 | 23 | - | 4-level deep graph assembly (0 N+1) |
| HQ04 (Account Relationship Graph with Optional Sub-Entities) | ✅ | 35.96 | 38.72 | 38.72 | 30 | - | Account graph with 7,000 joined records |
| HQ05 (Fleet & Route Profitability Ledger (5 Tables, 400k+ Rows)) | ✅ | 351.59 | 361.41 | 361.41 | 25 | - | 5-table analytical ledger over 410k rows |
| HQ06 (Chained Multi-Stage CTEs (Hub Centrality & Degree)) | ✅ | 89.74 | 94.01 | 94.01 | 52 | - | 3 chained CTEs hub centrality over 112k flights |
| HQ07 (Correlated At-Capacity Subquery + Loyalty Cross-Check) | ✅ | 107.43 | 114.44 | 114.44 | 33 | - | Correlated subqueries in SELECT & WHERE |
| HQ08 (Recursive Multi-Hop Flight Connection Graph (1-3 Hops)) | ✅ | 323.42 | 374.02 | 374.02 | 50 | - | Recursive 1- to 3-hop itinerary graph traversal |
| HQ09 (Multi-Window Statistical Delay Dispersion & Cascades) | ✅ | 6.35 | 6.50 | 6.50 | 45 | - | 4 simultaneous window functions with framing |
| HQ10 (Keyset (Cursor) Pagination over Composite Key Under Load) | ✅ | 13.47 | 13.93 | 13.93 | 12 | - | Composite keyset cursor pagination |
| HQ11 (High-Dimensional Dynamic Faceted Flight Search Engine) | ✅ | 10.03 | 11.47 | 11.47 | 49 | - | Dynamic faceted search with 10 predicates |
| HQ12 (High-Volume Batch Upsert (2,500 Records ON CONFLICT)) | ✅ | 9.07 | 9.81 | 9.81 | 22 | - | High-volume 2,500 rows batch upsert |
| HQ13 (Optimistic Concurrency Bulk Fare & Status Adjustment) | ✅ | 2.58 | 2.95 | 2.95 | 16 | - | Optimistic version increment |
| HQ14 (High-Concurrency Seat Allocation Under Contention (C=100)) | ✅ | 1.23 | 1.26 | 42.06 | 23 | 2266 | Concurrent seat reservation with FOR UPDATE |
| HQ15 (Distributed Financial / Points Transfer with 40001 Retry) | ✅ | 0.94 | 1.09 | 1.09 | 23 | - | Serializable points transfer with 40001 retry |
| HQ16 (Multi-Modal Hybrid Vector Similarity + BM25 RRF Search) | ✅ | 3.35 | 4.48 | 4.48 | 36 | - | Hybrid 384-dim HNSW + BM25 RRF search |

#### Deliberate Mistakes Diagnostics Summary:
```text
No diagnostic logs attached.
```

---

### SEA-ORM (Rust)
- **Framework Version**: 2.0.4
- **Benchmark Timestamp**: 2026-11-15T16:38:35.606652+00:00
- **Implementation Path**: `../sea-orm/sea-orm-postgres-air-bench`

#### Latency Distribution across Heavyweight Canonical Queries:
| Query | Status | p50 (ms) | p95 (ms) | p99 (ms) | LoC | Throughput | Notes |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| HQ01 (Massive Entity Deserialization (10k Wide Rows)) | ✅ | 8.17 | 8.71 | 8.71 | 8 | 1235677 | 10k flight entities hydrated |
| HQ02 (Wide Multi-Join Composite Hydration (5k Joined Rows)) | ✅ | 8.37 | 8.60 | 8.60 | 14 | 603444 | 5k 4-table joined records |
| HQ03 (4-Level Deep Entity Tree (Flight->Legs->Booking->Pass)) | ✅ | 2.10 | 2.29 | 2.29 | 22 | - | 4-level deep graph assembly (0 N+1) |
| HQ04 (Account Relationship Graph with Optional Sub-Entities) | ✅ | 14.50 | 14.92 | 14.92 | 26 | - | Account graph with 7,000 joined records |
| HQ05 (Fleet & Route Profitability Ledger (5 Tables, 400k+ Rows)) | ✅ | 358.42 | 398.04 | 398.04 | 22 | - | 5-table analytical ledger over 410k rows |
| HQ06 (Chained Multi-Stage CTEs (Hub Centrality & Degree)) | ✅ | 88.96 | 101.32 | 101.32 | 25 | - | 3 chained CTEs hub centrality over 112k flights |
| HQ07 (Correlated At-Capacity Subquery + Loyalty Cross-Check) | ✅ | 137.64 | 142.29 | 142.29 | 20 | - | Correlated subqueries in SELECT & WHERE |
| HQ08 (Recursive Multi-Hop Flight Connection Graph (1-3 Hops)) | ✅ | 334.12 | 339.63 | 339.63 | 24 | - | Recursive 1- to 3-hop itinerary graph traversal |
| HQ09 (Multi-Window Statistical Delay Dispersion & Cascades) | ✅ | 6.45 | 7.02 | 7.02 | 20 | - | 4 simultaneous window functions with framing |
| HQ10 (Keyset (Cursor) Pagination over Composite Key Under Load) | ✅ | 11.96 | 14.00 | 14.00 | 10 | - | Composite keyset cursor pagination |
| HQ11 (High-Dimensional Dynamic Faceted Flight Search Engine) | ✅ | 0.75 | 0.77 | 0.77 | 28 | - | Dynamic faceted search with 10 predicates |
| HQ12 (High-Volume Batch Upsert (2,500 Records ON CONFLICT)) | ✅ | 11.56 | 13.60 | 13.60 | 12 | - | SeaORM on_conflict 2,500 rows batch upsert |
| HQ13 (Optimistic Concurrency Bulk Fare & Status Adjustment) | ✅ | 0.55 | 0.63 | 0.63 | 8 | - | Optimistic version increment |
| HQ14 (High-Concurrency Seat Allocation Under Contention (C=100)) | ✅ | 0.85 | 0.92 | 0.92 | 16 | 253 | Concurrent seat reservation with FOR UPDATE |
| HQ15 (Distributed Financial / Points Transfer with 40001 Retry) | ✅ | 1.23 | 1.38 | 1.38 | 18 | - | Serializable points transfer with 40001 retry |
| HQ16 (Multi-Modal Hybrid Vector Similarity + BM25 RRF Search) | ✅ | 4.09 | 4.31 | 4.31 | 18 | - | Hybrid 384-dim HNSW + BM25 RRF search |

#### Deliberate Mistakes Diagnostics Summary:
```text
No diagnostic logs attached.
```

---

### ECTO (Elixir)
- **Framework Version**: 3.15.0-dev
- **Benchmark Timestamp**: 2026-11-14T20:16:04.649294Z
- **Implementation Path**: `../ecto/bench`

#### Latency Distribution across Heavyweight Canonical Queries:
| Query | Status | p50 (ms) | p95 (ms) | p99 (ms) | LoC | Throughput | Notes |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| HQ01 (Massive Entity Deserialization (10k Wide Rows)) | ✅ | 28.24 | 32.58 | 32.58 | 8 | 354070 | 10k flight entities hydrated |
| HQ02 (Wide Multi-Join Composite Hydration (5k Joined Rows)) | ✅ | 11.40 | 11.94 | 11.94 | 18 | 438635 | 5k 4-table joined records |
| HQ03 (4-Level Deep Entity Tree (Flight->Legs->Booking->Pass)) | ✅ | 10.79 | 11.94 | 11.94 | 24 | 204558 | 4-level deep graph assembly (0 N+1) |
| HQ04 (Account Relationship Graph with Optional Sub-Entities) | ✅ | 15.15 | 16.59 | 16.59 | 16 | - | Account graph with 7,000 joined records |
| HQ05 (Fleet & Route Profitability Ledger (5 Tables, 400k+ Rows)) | ✅ | 347.40 | 357.73 | 357.73 | 22 | - | 5-table analytical ledger over 410k rows |
| HQ06 (Chained Multi-Stage CTEs (Hub Centrality & Degree)) | ✅ | 87.99 | 90.62 | 90.62 | 26 | - | 3 chained CTEs hub centrality over 112k flights |
| HQ07 (Correlated At-Capacity Subquery + Loyalty Cross-Check) | ✅ | 135.51 | 138.22 | 138.22 | 22 | - | Correlated subqueries in SELECT & WHERE |
| HQ08 (Recursive Multi-Hop Flight Connection Graph (1-3 Hops)) | ✅ | 229.69 | 235.75 | 235.75 | 25 | - | Recursive 1- to 3-hop itinerary graph traversal |
| HQ09 (Multi-Window Statistical Delay Dispersion & Cascades) | ✅ | 7.44 | 7.94 | 7.94 | 20 | - | 4 simultaneous window functions with framing |
| HQ10 (Keyset (Cursor) Pagination over Composite Key Under Load) | ✅ | 0.46 | 0.55 | 0.55 | 12 | - | Composite keyset cursor pagination |
| HQ11 (High-Dimensional Dynamic Faceted Flight Search Engine) | ✅ | 0.76 | 0.83 | 0.83 | 26 | - | Dynamic faceted search with 10 predicates |
| HQ12 (High-Volume Batch Upsert (2,500 Records ON CONFLICT)) | ✅ | 15.27 | 16.27 | 16.27 | 14 | - | Ecto on_conflict 2,500 rows batch upsert |
| HQ13 (Optimistic Concurrency Bulk Fare & Status Adjustment) | ✅ | 3.09 | 3.42 | 3.42 | 10 | - | Optimistic version increment |
| HQ14 (High-Concurrency Seat Allocation Under Contention (C=100)) | ✅ | 1.31 | 2.15 | 2.15 | 16 | 763 | Concurrent seat reservation with FOR UPDATE |
| HQ15 (Distributed Financial / Points Transfer with 40001 Retry) | ✅ | 1.06 | 1.08 | 1.08 | 18 | - | Serializable points transfer with 40001 retry |
| HQ16 (Multi-Modal Hybrid Vector Similarity + BM25 RRF Search) | ✅ | 4.08 | 4.22 | 4.22 | 22 | - | Hybrid 384-dim HNSW + BM25 RRF search |

#### Deliberate Mistakes Diagnostics Summary:
```text
No diagnostic logs attached.
```

---

### JOOQ (Java)
- **Framework Version**: Java 21 / jOOQ 3.19.16
- **Benchmark Timestamp**: 2026-11-15T14:41:44.402184288Z
- **Implementation Path**: `../jOOQ/bench`

#### Latency Distribution across Heavyweight Canonical Queries:
| Query | Status | p50 (ms) | p95 (ms) | p99 (ms) | LoC | Throughput | Notes |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| HQ01 (Massive Entity Deserialization (10k Wide Rows)) | ✅ | 18.51 | 40.49 | 40.49 | 6 | 454966 | 10k flight entities hydrated |
| HQ02 (Wide Multi-Join Composite Hydration (5k Joined Rows)) | ✅ | 10.91 | 13.25 | 13.25 | 12 | 448469 | 5k 4-table joined records |
| HQ03 (4-Level Deep Entity Tree (Flight->Legs->Booking->Pass)) | ✅ | 3.09 | 4.93 | 4.93 | 20 | - | 4-level deep graph assembly (0 N+1) |
| HQ04 (Account Relationship Graph with Optional Sub-Entities) | ✅ | 1.47 | 2.30 | 2.69 | 20 | - | Account graph with 7,000 joined records |
| HQ05 (Fleet & Route Profitability Ledger (5 Tables, 400k+ Rows)) | ✅ | 384.35 | 392.77 | 392.77 | 30 | - | 5-table analytical ledger over 410k rows |
| HQ06 (Chained Multi-Stage CTEs (Hub Centrality & Degree)) | ✅ | 109.82 | 114.00 | 114.00 | 50 | - | 3 chained CTEs hub centrality over 112k flights |
| HQ07 (Correlated At-Capacity Subquery + Loyalty Cross-Check) | ✅ | 0.53 | 0.98 | 1.13 | 30 | - | Correlated subqueries in SELECT & WHERE |
| HQ08 (Recursive Multi-Hop Flight Connection Graph (1-3 Hops)) | ✅ | 305.69 | 307.74 | 307.74 | 38 | - | Recursive 1- to 3-hop itinerary graph traversal |
| HQ09 (Multi-Window Statistical Delay Dispersion & Cascades) | ✅ | 7.74 | 10.77 | 10.77 | 32 | - | 4 simultaneous window functions with framing |
| HQ10 (Keyset (Cursor) Pagination over Composite Key Under Load) | ✅ | 0.62 | 1.03 | 2.50 | 8 | - | Composite keyset cursor pagination |
| HQ11 (High-Dimensional Dynamic Faceted Flight Search Engine) | ✅ | 0.62 | 0.80 | 0.88 | 40 | - | Dynamic faceted search with 10 predicates |
| HQ12 (High-Volume Batch Upsert (2,500 Records ON CONFLICT)) | ✅ | 14.67 | 27.03 | 27.03 | 25 | - | High-volume 2,500 rows batch upsert |
| HQ13 (Optimistic Concurrency Bulk Fare & Status Adjustment) | ✅ | 0.13 | 0.16 | 0.20 | 10 | - | Optimistic version increment |
| HQ14 (High-Concurrency Seat Allocation Under Contention (C=100)) | ✅ | 0.17 | 0.27 | 0.47 | 22 | - | Concurrent seat reservation with FOR UPDATE |
| HQ15 (Distributed Financial / Points Transfer with 40001 Retry) | ✅ | 0.41 | 0.64 | 0.67 | 28 | - | Serializable points transfer with 40001 retry |
| HQ16 (Multi-Modal Hybrid Vector Similarity + BM25 RRF Search) | ✅ | 5.99 | 6.26 | 6.26 | 40 | - | Hybrid 384-dim HNSW + BM25 RRF search |

#### Deliberate Mistakes Diagnostics Summary:
```text
No diagnostic logs attached.
```

---

### GORM (Go)
- **Framework Version**: go1.25 / gorm v1.31.2
- **Benchmark Timestamp**: 2026-11-15T04:55:30.368945316Z
- **Implementation Path**: `../gorm/bench`

#### Latency Distribution across Heavyweight Canonical Queries:
| Query | Status | p50 (ms) | p95 (ms) | p99 (ms) | LoC | Throughput | Notes |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| HQ01 (Massive Entity Deserialization (10k Wide Rows)) | ✅ | 14.38 | 15.09 | 15.09 | 6 | 712657 | 10k flight entities hydrated |
| HQ02 (Wide Multi-Join Composite Hydration (5k Joined Rows)) | ✅ | 10.98 | 11.29 | 11.29 | 14 | 481556 | 5k 4-table joined records |
| HQ03 (4-Level Deep Entity Tree (Flight->Legs->Booking->Pass)) | ✅ | 4.36 | 4.64 | 4.64 | 11 | - | 4-level deep graph assembly (0 N+1) |
| HQ04 (Account Relationship Graph with Optional Sub-Entities) | ✅ | 2.55 | 2.67 | 2.67 | 11 | - | Account graph with optional sub-entities |
| HQ05 (Fleet & Route Profitability Ledger (5 Tables, 400k+ Rows)) | ✅ | 345.93 | 373.01 | 373.01 | 18 | - | 5-table analytical ledger over 410k rows |
| HQ06 (Chained Multi-Stage CTEs (Hub Centrality & Degree)) | ✅ | 82.54 | 87.63 | 87.63 | 50 | - | 3 chained CTEs hub centrality over 112k flights |
| HQ07 (Correlated At-Capacity Subquery + Loyalty Cross-Check) | ✅ | 99.07 | 99.41 | 99.41 | 36 | - | Correlated subqueries in SELECT & WHERE |
| HQ08 (Recursive Multi-Hop Flight Connection Graph (1-3 Hops)) | ✅ | 299.49 | 304.38 | 304.38 | 48 | - | Recursive 1- to 3-hop itinerary graph traversal |
| HQ09 (Multi-Window Statistical Delay Dispersion & Cascades) | ✅ | 5.35 | 5.47 | 5.47 | 42 | - | 4 simultaneous window functions with framing |
| HQ10 (Keyset (Cursor) Pagination over Composite Key Under Load) | ✅ | 12.58 | 13.24 | 13.24 | 12 | - | Composite keyset cursor pagination |
| HQ11 (High-Dimensional Dynamic Faceted Flight Search Engine) | ✅ | 0.29 | 0.32 | 0.32 | 52 | - | Dynamic faceted search with 10 predicates |
| HQ12 (High-Volume Batch Upsert (2,500 Records ON CONFLICT)) | ✅ | 7.91 | 11.48 | 11.48 | 27 | - | High-volume 2,500 rows batch upsert |
| HQ13 (Optimistic Concurrency Bulk Fare & Status Adjustment) | ✅ | 2.65 | 2.81 | 2.81 | 23 | - | Optimistic version increment |
| HQ14 (High-Concurrency Seat Allocation Under Contention (C=100)) | ✅ | 0.73 | 0.81 | 27.91 | 36 | 3563 | Concurrent seat reservation with FOR UPDATE |
| HQ15 (Distributed Financial / Points Transfer with 40001 Retry) | ✅ | 0.65 | 0.73 | 0.73 | 42 | - | Serializable points transfer with 40001 retry |
| HQ16 (Multi-Modal Hybrid Vector Similarity + BM25 RRF Search) | ✅ | 2.80 | 3.09 | 3.09 | 35 | - | Hybrid 384-dim HNSW + BM25 RRF search |

#### Deliberate Mistakes Diagnostics Summary:
```text
No diagnostic logs attached.
```

---

### ENT (Go)
- **Framework Version**: v0.14.2
- **Benchmark Timestamp**: 2026-11-15T17:59:20.457847391Z
- **Implementation Path**: `../ent/bench`

#### Latency Distribution across Heavyweight Canonical Queries:
| Query | Status | p50 (ms) | p95 (ms) | p99 (ms) | LoC | Throughput | Notes |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| HQ01 (Massive Entity Deserialization (10k Wide Rows)) | ✅ | 17.34 | 18.16 | 18.16 | 20 | 570841 | 10k flight entities hydrated |
| HQ02 (Wide Multi-Join Composite Hydration (5k Joined Rows)) | ✅ | 11.91 | 12.88 | 12.88 | 24 | 414766 | 5k 4-table joined records |
| HQ03 (4-Level Deep Entity Tree (Flight->Legs->Booking->Pass)) | ✅ | 3.22 | 3.64 | 3.64 | 42 | - | 4-level deep graph assembly (0 N+1) |
| HQ04 (Account Relationship Graph with Optional Sub-Entities) | ✅ | 0.21 | 0.22 | 0.22 | 19 | - | Account graph with optional sub-entities |
| HQ05 (Fleet & Route Profitability Ledger (5 Tables, 400k+ Rows)) | ✅ | 386.23 | 404.62 | 404.62 | 24 | - | 5-table analytical ledger over 410k rows |
| HQ06 (Chained Multi-Stage CTEs (Hub Centrality & Degree)) | ✅ | 88.29 | 89.39 | 89.39 | 50 | - | 3 chained CTEs hub centrality over 112k flights |
| HQ07 (Correlated At-Capacity Subquery + Loyalty Cross-Check) | ✅ | 106.10 | 109.10 | 109.10 | 40 | - | Correlated subqueries in SELECT & WHERE |
| HQ08 (Recursive Multi-Hop Flight Connection Graph (1-3 Hops)) | ✅ | 307.51 | 308.09 | 308.09 | 46 | - | Recursive 1- to 3-hop itinerary graph traversal |
| HQ09 (Multi-Window Statistical Delay Dispersion & Cascades) | ✅ | 5.60 | 5.78 | 5.78 | 36 | - | 4 simultaneous window functions with framing |
| HQ10 (Keyset (Cursor) Pagination over Composite Key Under Load) | ✅ | 13.42 | 14.38 | 14.38 | 24 | - | Composite keyset cursor pagination |
| HQ11 (High-Dimensional Dynamic Faceted Flight Search Engine) | ✅ | 0.30 | 0.33 | 0.33 | 58 | - | Dynamic faceted search with 10 predicates |
| HQ12 (High-Volume Batch Upsert (2,500 Records ON CONFLICT)) | ✅ | 7.68 | 8.19 | 8.19 | 26 | - | High-volume 2,500 rows batch upsert |
| HQ13 (Optimistic Concurrency Bulk Fare & Status Adjustment) | ✅ | 2.45 | 2.63 | 2.63 | 18 | - | Optimistic version increment |
| HQ14 (High-Concurrency Seat Allocation Under Contention (C=100)) | ✅ | 0.65 | 0.70 | 24.02 | 38 | 4111 | Concurrent seat reservation with FOR UPDATE |
| HQ15 (Distributed Financial / Points Transfer with 40001 Retry) | ✅ | 0.46 | 0.47 | 0.47 | 42 | - | Serializable points transfer with 40001 retry |
| HQ16 (Multi-Modal Hybrid Vector Similarity + BM25 RRF Search) | ✅ | 2.75 | 3.24 | 3.24 | 34 | - | Hybrid 384-dim HNSW + BM25 RRF search |

#### Deliberate Mistakes Diagnostics Summary:
```text
No diagnostic logs attached.
```

---

### HIBERNATE-ORM (Java)
- **Framework Version**: Java 21 / Hibernate 6.6.1.Final
- **Benchmark Timestamp**: 2026-11-15T09:53:05.557906089Z
- **Implementation Path**: `../hibernate-orm/bench`

#### Latency Distribution across Heavyweight Canonical Queries:
| Query | Status | p50 (ms) | p95 (ms) | p99 (ms) | LoC | Throughput | Notes |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| HQ01 (Massive Entity Deserialization (10k Wide Rows)) | ✅ | 15.46 | 30.38 | 30.38 | 6 | 564130 | 10k flight entities hydrated |
| HQ02 (Wide Multi-Join Composite Hydration (5k Joined Rows)) | ✅ | 16.73 | 28.99 | 28.99 | 12 | 281821 | 5k 4-table joined records |
| HQ03 (4-Level Deep Entity Tree (Flight->Legs->Booking->Pass)) | ✅ | 7.69 | 11.11 | 11.11 | 22 | - | 4-level deep graph assembly (0 N+1) |
| HQ04 (Account Relationship Graph with Optional Sub-Entities) | ✅ | 1.66 | 2.34 | 2.34 | 20 | - | Account graph with 7,000 joined records |
| HQ05 (Fleet & Route Profitability Ledger (5 Tables, 400k+ Rows)) | ✅ | 387.72 | 454.18 | 454.18 | 30 | - | 5-table analytical ledger over 410k rows |
| HQ06 (Chained Multi-Stage CTEs (Hub Centrality & Degree)) | ✅ | 87.60 | 107.29 | 107.29 | 55 | - | 3 chained CTEs hub centrality over 112k flights |
| HQ07 (Correlated At-Capacity Subquery + Loyalty Cross-Check) | ✅ | 0.46 | 0.71 | 0.71 | 32 | - | Correlated subqueries in SELECT & WHERE |
| HQ08 (Recursive Multi-Hop Flight Connection Graph (1-3 Hops)) | ✅ | 302.09 | 316.38 | 316.38 | 40 | - | Recursive 1- to 3-hop itinerary graph traversal |
| HQ09 (Multi-Window Statistical Delay Dispersion & Cascades) | ✅ | 8.83 | 10.76 | 10.76 | 35 | - | 4 simultaneous window functions with framing |
| HQ10 (Keyset (Cursor) Pagination over Composite Key Under Load) | ✅ | 12.36 | 13.18 | 13.60 | 10 | - | Composite keyset cursor pagination |
| HQ11 (High-Dimensional Dynamic Faceted Flight Search Engine) | ✅ | 1.11 | 1.37 | 1.68 | 45 | - | Dynamic faceted search with 10 predicates |
| HQ12 (High-Volume Batch Upsert (2,500 Records ON CONFLICT)) | ✅ | 15.72 | 16.32 | 16.32 | 28 | - | High-volume 2,500 rows batch upsert |
| HQ13 (Optimistic Concurrency Bulk Fare & Status Adjustment) | ✅ | 0.29 | 1.06 | 1.06 | 20 | - | Optimistic version increment |
| HQ14 (High-Concurrency Seat Allocation Under Contention (C=100)) | ✅ | 0.76 | 0.85 | 0.85 | 25 | - | Concurrent seat reservation with FOR UPDATE |
| HQ15 (Distributed Financial / Points Transfer with 40001 Retry) | ✅ | 1.15 | 1.87 | 1.87 | 30 | - | Serializable points transfer with 40001 retry |
| HQ16 (Multi-Modal Hybrid Vector Similarity + BM25 RRF Search) | ✅ | 5.47 | 5.75 | 5.75 | 42 | - | Hybrid 384-dim HNSW + BM25 RRF search |

#### Deliberate Mistakes Diagnostics Summary:
```text
No diagnostic logs attached.
```

---

### SQLALCHEMY (Python)
- **Framework Version**: Python 3.14.6 / SQLAlchemy 2.1.9
- **Benchmark Timestamp**: 2026-11-15T16:52:49.594398+00:00
- **Implementation Path**: `../sqlalchemy/sqlalchemy-postgres-air-bench`

#### Latency Distribution across Heavyweight Canonical Queries:
| Query | Status | p50 (ms) | p95 (ms) | p99 (ms) | LoC | Throughput | Notes |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| HQ01 (Massive Entity Deserialization (10k Wide Rows)) | ✅ | 31.98 | 42.18 | 42.18 | 4 | 279239 | 10k flight entities hydrated |
| HQ02 (Wide Multi-Join Composite Hydration (5k Joined Rows)) | ✅ | 11.34 | 11.82 | 11.82 | 25 | 438708 | 5k 4-table joined records |
| HQ03 (4-Level Deep Entity Tree (Flight->Legs->Booking->Pass)) | ✅ | 15.12 | 23.57 | 23.57 | 10 | - | 4-level deep graph assembly with selectinload (0 N+1) |
| HQ04 (Account Relationship Graph with Optional Sub-Entities) | ✅ | 27.84 | 37.92 | 37.92 | 10 | - | Account graph with nested selectinload |
| HQ05 (Fleet & Route Profitability Ledger (5 Tables, 400k+ Rows)) | ✅ | 371.49 | 392.92 | 392.92 | 32 | - | 5-table analytical ledger over 410k rows |
| HQ06 (Chained Multi-Stage CTEs (Hub Centrality & Degree)) | ✅ | 88.22 | 88.84 | 88.84 | 55 | - | 3 chained CTEs hub centrality over 112k flights |
| HQ07 (Correlated At-Capacity Subquery + Loyalty Cross-Check) | ✅ | 103.76 | 135.75 | 135.75 | 35 | - | Correlated subqueries in SELECT & WHERE |
| HQ08 (Recursive Multi-Hop Flight Connection Graph (1-3 Hops)) | ✅ | 305.13 | 306.40 | 306.40 | 38 | - | Recursive 1- to 3-hop itinerary graph traversal |
| HQ09 (Multi-Window Statistical Delay Dispersion & Cascades) | ✅ | 7.72 | 8.01 | 8.01 | 36 | - | 4 simultaneous window functions with framing |
| HQ10 (Keyset (Cursor) Pagination over Composite Key Under Load) | ✅ | 0.43 | 0.44 | 0.44 | 14 | - | Composite keyset cursor pagination |
| HQ11 (High-Dimensional Dynamic Faceted Flight Search Engine) | ✅ | 0.67 | 0.75 | 0.75 | 35 | - | Dynamic faceted search with 10 predicates |
| HQ12 (High-Volume Batch Upsert (2,500 Records ON CONFLICT)) | ✅ | 102.53 | 105.17 | 105.17 | 14 | - | SQLAlchemy on_conflict_do_update 2,500 rows batch upsert |
| HQ13 (Optimistic Concurrency Bulk Fare & Status Adjustment) | ✅ | 0.92 | 0.97 | 0.97 | 14 | - | Optimistic version increment |
| HQ14 (High-Concurrency Seat Allocation Under Contention (C=100)) | ✅ | 0.77 | 0.81 | 0.81 | 18 | 5718 | Concurrent seat reservation with FOR UPDATE |
| HQ15 (Distributed Financial / Points Transfer with 40001 Retry) | ✅ | 1.49 | 1.59 | 1.59 | 25 | - | Serializable points transfer with 40001 retry |
| HQ16 (Multi-Modal Hybrid Vector Similarity + BM25 RRF Search) | ✅ | 3.59 | 3.93 | 3.93 | 45 | - | Hybrid 384-dim HNSW + BM25 RRF search |

#### Deliberate Mistakes Diagnostics Summary:
```text
No diagnostic logs attached.
```

---

### MIKRO-ORM (TypeScript)
- **Framework Version**: Node.js 26 / MikroORM 7.2.9
- **Benchmark Timestamp**: 2026-11-15T15:24:38.667Z
- **Implementation Path**: `../mikro-orm/bench`

#### Latency Distribution across Heavyweight Canonical Queries:
| Query | Status | p50 (ms) | p95 (ms) | p99 (ms) | LoC | Throughput | Notes |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| HQ01 (Massive Entity Deserialization (10k Wide Rows)) | ✅ | 54.77 | 68.78 | 68.78 | 6 | 182594 | 10k flight entities hydrated |
| HQ02 (Wide Multi-Join Composite Hydration (5k Joined Rows)) | ✅ | 7.29 | 9.11 | 9.11 | 14 | 685816 | 5k 4-table joined records |
| HQ03 (4-Level Deep Entity Tree (Flight->Legs->Booking->Pass)) | ✅ | 3.03 | 4.38 | 4.38 | 24 | - | 4-level deep graph assembly (0 N+1) |
| HQ04 (Account Relationship Graph with Optional Sub-Entities) | ✅ | 1.32 | 2.69 | 2.69 | 28 | - | Account graph with 7,000 joined records |
| HQ05 (Fleet & Route Profitability Ledger (5 Tables, 400k+ Rows)) | ✅ | 364.72 | 394.07 | 394.07 | 24 | - | 5-table analytical ledger over 410k rows |
| HQ06 (Chained Multi-Stage CTEs (Hub Centrality & Degree)) | ✅ | 86.85 | 87.50 | 87.50 | 26 | - | 3 chained CTEs hub centrality over 112k flights |
| HQ07 (Correlated At-Capacity Subquery + Loyalty Cross-Check) | ✅ | 0.45 | 0.55 | 0.55 | 22 | - | Correlated subqueries in SELECT & WHERE |
| HQ08 (Recursive Multi-Hop Flight Connection Graph (1-3 Hops)) | ✅ | 300.97 | 307.24 | 307.24 | 25 | - | Recursive 1- to 3-hop itinerary graph traversal |
| HQ09 (Multi-Window Statistical Delay Dispersion & Cascades) | ✅ | 6.99 | 8.95 | 8.95 | 20 | - | 4 simultaneous window functions with framing |
| HQ10 (Keyset (Cursor) Pagination over Composite Key Under Load) | ✅ | 0.61 | 0.76 | 0.76 | 10 | - | Composite keyset cursor pagination |
| HQ11 (High-Dimensional Dynamic Faceted Flight Search Engine) | ✅ | 0.79 | 1.12 | 1.12 | 28 | - | Dynamic faceted search with 10 predicates |
| HQ12 (High-Volume Batch Upsert (2,500 Records ON CONFLICT)) | ✅ | 12.59 | 13.01 | 13.01 | 14 | - | MikroORM 2,500 rows batch upsert |
| HQ13 (Optimistic Concurrency Bulk Fare & Status Adjustment) | ✅ | 0.20 | 0.25 | 0.25 | 8 | - | Optimistic version increment |
| HQ14 (High-Concurrency Seat Allocation Under Contention (C=100)) | ✅ | 12.26 | 13.45 | 13.45 | 18 | 3118 | Concurrent seat reservation with FOR UPDATE |
| HQ15 (Distributed Financial / Points Transfer with 40001 Retry) | ✅ | 12.93 | 13.08 | 13.08 | 20 | - | Serializable points transfer with 40001 retry |
| HQ16 (Multi-Modal Hybrid Vector Similarity + BM25 RRF Search) | ✅ | 5.79 | 6.17 | 6.17 | 20 | - | Hybrid 384-dim HNSW + BM25 RRF search |

#### Deliberate Mistakes Diagnostics Summary:
```text
No diagnostic logs attached.
```

---

### DRIZZLE-ORM (TypeScript)
- **Framework Version**: 0.45.4
- **Benchmark Timestamp**: 2026-11-14T19:54:51.275Z
- **Implementation Path**: `../drizzle-orm/bench`

#### Latency Distribution across Heavyweight Canonical Queries:
| Query | Status | p50 (ms) | p95 (ms) | p99 (ms) | LoC | Throughput | Notes |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| HQ01 (Massive Entity Deserialization (10k Wide Rows)) | ✅ | 20.06 | 23.39 | 23.39 | 6 | 498613 | 10k flight entities hydrated |
| HQ02 (Wide Multi-Join Composite Hydration (5k Joined Rows)) | ✅ | 11.74 | 13.30 | 13.30 | 14 | 426029 | 5k 4-table joined records |
| HQ03 (4-Level Deep Entity Tree (Flight->Legs->Booking->Pass)) | ✅ | 5.51 | 6.13 | 6.13 | 24 | 245374 | 4-level deep graph assembly (0 N+1) |
| HQ04 (Account Relationship Graph with Optional Sub-Entities) | ✅ | 18.06 | 42.55 | 42.55 | 28 | - | Account graph with 7,000 joined records |
| HQ05 (Fleet & Route Profitability Ledger (5 Tables, 400k+ Rows)) | ✅ | 301.77 | 305.55 | 305.55 | 24 | - | 5-table analytical ledger over 410k rows |
| HQ06 (Chained Multi-Stage CTEs (Hub Centrality & Degree)) | ✅ | 91.10 | 94.15 | 94.15 | 26 | - | 3 chained CTEs hub centrality over 112k flights |
| HQ07 (Correlated At-Capacity Subquery + Loyalty Cross-Check) | ✅ | 106.01 | 132.69 | 132.69 | 22 | - | Correlated subqueries in SELECT & WHERE |
| HQ08 (Recursive Multi-Hop Flight Connection Graph (1-3 Hops)) | ✅ | 300.72 | 342.53 | 342.53 | 25 | - | Recursive 1- to 3-hop itinerary graph traversal |
| HQ09 (Multi-Window Statistical Delay Dispersion & Cascades) | ✅ | 5.60 | 6.11 | 6.11 | 20 | - | 4 simultaneous window functions with framing |
| HQ10 (Keyset (Cursor) Pagination over Composite Key Under Load) | ✅ | 11.99 | 12.32 | 12.32 | 10 | - | Composite keyset cursor pagination |
| HQ11 (High-Dimensional Dynamic Faceted Flight Search Engine) | ✅ | 0.82 | 0.97 | 0.98 | 28 | - | Dynamic faceted search with 10 predicates |
| HQ12 (High-Volume Batch Upsert (2,500 Records ON CONFLICT)) | ✅ | 39.31 | 43.77 | 43.77 | 14 | - | Drizzle onConflictDoUpdate 2,500 rows batch upsert |
| HQ13 (Optimistic Concurrency Bulk Fare & Status Adjustment) | ✅ | 1.58 | 2.26 | 2.26 | 8 | - | Optimistic version increment |
| HQ14 (High-Concurrency Seat Allocation Under Contention (C=100)) | ✅ | 0.99 | 1.07 | 1.33 | 18 | 225 | Concurrent seat reservation with forUpdate |
| HQ15 (Distributed Financial / Points Transfer with 40001 Retry) | ✅ | 1.12 | 1.16 | 1.16 | 20 | - | Serializable points transfer with 40001 retry |
| HQ16 (Multi-Modal Hybrid Vector Similarity + BM25 RRF Search) | ✅ | 3.12 | 3.19 | 3.19 | 20 | - | Hybrid 384-dim HNSW + BM25 RRF search |

#### Deliberate Mistakes Diagnostics Summary:
```text
No diagnostic logs attached.
```

---

### TYPEORM (TypeScript)
- **Framework Version**: Node.js 26 / TypeORM 1.1.3
- **Benchmark Timestamp**: 2026-11-15T17:39:15.786Z
- **Implementation Path**: `../typeorm/bench`

#### Latency Distribution across Heavyweight Canonical Queries:
| Query | Status | p50 (ms) | p95 (ms) | p99 (ms) | LoC | Throughput | Notes |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| HQ01 (Massive Entity Deserialization (10k Wide Rows)) | ✅ | 25.95 | 41.69 | 41.69 | 7 | 385422 | 10k flight entities hydrated |
| HQ02 (Wide Multi-Join Composite Hydration (5k Joined Rows)) | ✅ | 8.16 | 9.18 | 9.18 | 14 | 612989 | 5k 4-table joined records |
| HQ03 (4-Level Deep Entity Tree (Flight->Legs->Booking->Pass)) | ✅ | 3.58 | 4.90 | 4.90 | 24 | - | 4-level deep graph assembly (0 N+1) |
| HQ04 (Account Relationship Graph with Optional Sub-Entities) | ✅ | 1.29 | 2.48 | 2.48 | 28 | - | Account graph assembly |
| HQ05 (Fleet & Route Profitability Ledger (5 Tables, 400k+ Rows)) | ✅ | 362.58 | 364.43 | 364.43 | 24 | - | 5-table analytical ledger over 410k rows |
| HQ06 (Chained Multi-Stage CTEs (Hub Centrality & Degree)) | ✅ | 87.55 | 96.88 | 96.88 | 26 | - | 3 chained CTEs hub centrality over 112k flights |
| HQ07 (Correlated At-Capacity Subquery + Loyalty Cross-Check) | ✅ | 0.47 | 0.55 | 0.55 | 22 | - | Correlated subqueries in SELECT & WHERE |
| HQ08 (Recursive Multi-Hop Flight Connection Graph (1-3 Hops)) | ✅ | 306.10 | 326.54 | 326.54 | 25 | - | Recursive 1- to 3-hop itinerary graph traversal |
| HQ09 (Multi-Window Statistical Delay Dispersion & Cascades) | ✅ | 2.02 | 2.34 | 2.34 | 20 | - | 4 simultaneous window functions with framing |
| HQ10 (Keyset (Cursor) Pagination over Composite Key Under Load) | ✅ | 12.80 | 14.05 | 14.05 | 10 | - | Composite keyset cursor pagination |
| HQ11 (High-Dimensional Dynamic Faceted Flight Search Engine) | ✅ | 0.51 | 0.66 | 0.66 | 28 | - | Dynamic faceted search with 10 predicates |
| HQ12 (High-Volume Batch Upsert (2,500 Records ON CONFLICT)) | ✅ | 23.38 | 24.04 | 24.04 | 16 | - | TypeORM 2,500 rows batch upsert |
| HQ13 (Optimistic Concurrency Bulk Fare & Status Adjustment) | ✅ | 0.27 | 0.40 | 0.40 | 12 | - | Optimistic version increment |
| HQ14 (High-Concurrency Seat Allocation Under Contention (C=100)) | ✅ | 0.56 | 0.62 | 0.62 | 18 | 225 | Concurrent seat reservation with pessimistic_write lock |
| HQ15 (Distributed Financial / Points Transfer with 40001 Retry) | ✅ | 1.00 | 1.20 | 1.20 | 20 | - | Serializable points transfer with 40001 retry |
| HQ16 (Multi-Modal Hybrid Vector Similarity + BM25 RRF Search) | ✅ | 5.75 | 5.87 | 5.87 | 20 | - | Hybrid 384-dim HNSW + BM25 RRF search |

#### Deliberate Mistakes Diagnostics Summary:
```text
No diagnostic logs attached.
```

---

### HASQL (Haskell)
- **Framework Version**: 2.1.0.0
- **Benchmark Timestamp**: 2026-11-15 18:12:01.576496 UTC
- **Implementation Path**: `../hasql/hasql-postgres-air-bench`

#### Latency Distribution across Heavyweight Canonical Queries:
| Query | Status | p50 (ms) | p95 (ms) | p99 (ms) | LoC | Throughput | Notes |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| HQ01 (Massive Entity Deserialization (10k Wide Rows)) | ✅ | 50.24 | 60.44 | 60.44 | 25 | 199025 | 10k flight entities hydrated |
| HQ02 (Wide Multi-Join Composite Hydration (5k Joined Rows)) | ✅ | 37.39 | 38.75 | 38.75 | 35 | 133718 | 5k 4-table joined records |
| HQ03 (4-Level Deep Entity Tree (Flight->Legs->Booking->Pass)) | ✅ | 3.98 | 4.05 | 4.05 | 20 | - | 4-level deep graph assembly |
| HQ04 (Account Relationship Graph with Optional Sub-Entities) | ✅ | 49.35 | 50.50 | 50.50 | 30 | - | Account relationship graph |
| HQ05 (Fleet & Route Profitability Ledger (5 Tables, 400k+ Rows)) | ✅ | 349.21 | 351.99 | 351.99 | 30 | - | 5-table analytical ledger over 410k rows |
| HQ06 (Chained Multi-Stage CTEs (Hub Centrality & Degree)) | ✅ | 86.11 | 86.73 | 86.73 | 45 | - | 3 chained CTEs hub centrality over 112k flights |
| HQ07 (Correlated At-Capacity Subquery + Loyalty Cross-Check) | ✅ | 102.84 | 117.22 | 117.22 | 35 | - | Correlated subqueries in SELECT & WHERE |
| HQ08 (Recursive Multi-Hop Flight Connection Graph (1-3 Hops)) | ✅ | 301.74 | 302.51 | 302.51 | 45 | - | Recursive 1- to 3-hop itinerary graph traversal |
| HQ09 (Multi-Window Statistical Delay Dispersion & Cascades) | ✅ | 12.64 | 12.91 | 12.91 | 40 | - | 4 simultaneous window functions with framing |
| HQ10 (Keyset (Cursor) Pagination over Composite Key Under Load) | ✅ | 11.78 | 12.03 | 12.03 | 20 | - | Composite keyset cursor pagination |
| HQ11 (High-Dimensional Dynamic Faceted Flight Search Engine) | ✅ | 0.45 | 0.49 | 0.49 | 35 | - | Dynamic faceted search with 10 predicates |
| HQ12 (High-Volume Batch Upsert (2,500 Records ON CONFLICT)) | ✅ | 8.18 | 8.26 | 8.26 | 15 | - | High-volume 2,500 rows batch upsert |
| HQ13 (Optimistic Concurrency Bulk Fare & Status Adjustment) | ✅ | 2.38 | 2.74 | 2.74 | 18 | - | Optimistic version increment |
| HQ14 (High-Concurrency Seat Allocation Under Contention (C=100)) | ✅ | 0.55 | 0.78 | 0.78 | 25 | 3548 | Concurrent seat reservation with FOR UPDATE |
| HQ15 (Distributed Financial / Points Transfer with 40001 Retry) | ✅ | 0.89 | 0.92 | 0.92 | 25 | - | Serializable points transfer with retry |
| HQ16 (Multi-Modal Hybrid Vector Similarity + BM25 RRF Search) | ✅ | 2.95 | 3.00 | 3.00 | 30 | - | Hybrid 384-dim HNSW + BM25 RRF search |

#### Deliberate Mistakes Diagnostics Summary:
```text
No diagnostic logs attached.
```

---

### IHP (Haskell)
- **Framework Version**: 1.6.0
- **Benchmark Timestamp**: 2026-11-16 00:29:28 UTC
- **Implementation Path**: `../ihp/ihp-postgres-air-bench`

#### Latency Distribution across Heavyweight Canonical Queries:
| Query | Status | p50 (ms) | p95 (ms) | p99 (ms) | LoC | Throughput | Notes |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| HQ01 (Massive Entity Deserialization (10k Wide Rows)) | ✅ | 67.85 | 75.64 | 75.64 | 25 | 144224 | 10k flight entities hydrated via IHP fetch |
| HQ02 (Wide Multi-Join Composite Hydration (5k Joined Rows)) | ✅ | 51.57 | 54.03 | 54.03 | 35 | 96505 | 5k 4-table joined records via unsafeSqlQuery |
| HQ03 (4-Level Deep Entity Tree (Flight->Legs->Booking->Pass)) | ✅ | 4.91 | 4.99 | 4.99 | 20 | - | 4-level deep hierarchy assembly |
| HQ04 (Account Relationship Graph with Optional Sub-Entities) | ✅ | 67.29 | 74.60 | 74.60 | 30 | - | Account relationship graph with outer joins |
| HQ05 (Fleet & Route Profitability Ledger (5 Tables, 400k+ Rows)) | ✅ | 364.34 | 369.94 | 369.94 | 35 | - | 5-table analytical route profitability ledger |
| HQ06 (Chained Multi-Stage CTEs (Hub Centrality & Degree)) | ✅ | 87.11 | 87.32 | 87.32 | 45 | - | 3 chained CTEs for hub centrality and network degree |
| HQ07 (Correlated At-Capacity Subquery + Loyalty Cross-Check) | ✅ | 103.57 | 104.77 | 104.77 | 35 | - | Correlated capacity subqueries with loyalty cross-check |
| HQ08 (Recursive Multi-Hop Flight Connection Graph (1-3 Hops)) | ✅ | 303.25 | 304.03 | 304.03 | 45 | - | Recursive multi-hop flight connection graph search |
| HQ09 (Multi-Window Statistical Delay Dispersion & Cascades) | ✅ | 15.76 | 16.73 | 16.73 | 40 | - | Multi-window statistical delay dispersion and cascades |
| HQ10 (Keyset (Cursor) Pagination over Composite Key Under Load) | ✅ | 8.88 | 9.02 | 9.02 | 20 | - | High-throughput keyset cursor pagination |
| HQ11 (High-Dimensional Dynamic Faceted Flight Search Engine) | ✅ | 0.53 | 0.57 | 0.57 | 35 | - | Dynamic faceted flight search with multi-parameter filter |
| HQ12 (High-Volume Batch Upsert (2,500 Records ON CONFLICT)) | ✅ | 17.76 | 17.76 | 17.76 | 15 | - | High-volume 2,500 record batch upsert ON CONFLICT |
| HQ13 (Optimistic Concurrency Bulk Fare & Status Adjustment) | ✅ | 2.56 | 2.72 | 2.72 | 18 | - | Optimistic concurrency bulk update |
| HQ14 (High-Concurrency Seat Allocation Under Contention (C=100)) | ✅ | 0.44 | 0.54 | 0.54 | 25 | 9565 | High-concurrency seat allocation under contention |
| HQ15 (Distributed Financial / Points Transfer with 40001 Retry) | ✅ | 0.71 | 0.75 | 0.75 | 25 | - | Distributed financial points transfer in transaction |
| HQ16 (Multi-Modal Hybrid Vector Similarity + BM25 RRF Search) | ✅ | 2.94 | 3.19 | 3.19 | 30 | - | Multi-modal hybrid pgvector + BM25 RRF search |

#### Deliberate Mistakes Diagnostics Summary:
```text
E01_TypeMismatch: 9 lines | PASS (Zero Leakage)
E02_JoinKeyMismatch: 9 lines | PASS (Zero Leakage)
E03_MissingGroupBy: 25 lines | PASS (Zero Leakage)
E04_IoEscape: 13 lines | PASS (Zero Leakage)
E05_NullabilityViolation: 12 lines | PASS (Zero Leakage)
E06_UnknownColumn: 26 lines | PASS (Zero Leakage)
E07_WindowInWhere: 8 lines | PASS (Zero Leakage)
E08_DanglingJoin: 8 lines | PASS (Zero Leakage)
E09_MutatePrimaryKey: 12 lines | PASS (Zero Leakage)
E10_ScopeLeak: 2 lines | PASS (Zero Leakage)
```

---

### ORVILLE (Haskell)
- **Framework Version**: 1.1.1.0
- **Benchmark Timestamp**: 2026-11-15T00:00:00Z
- **Implementation Path**: `../orville/orville-postgres-air-bench`

#### Latency Distribution across Heavyweight Canonical Queries:
| Query | Status | p50 (ms) | p95 (ms) | p99 (ms) | LoC | Throughput | Notes |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| HQ01 (Massive Entity Deserialization (10k Wide Rows)) | ✅ | 101.31 | 109.73 | 109.73 | 6 | 99705 | 10k flight entities hydrated |
| HQ02 (Wide Multi-Join Composite Hydration (5k Joined Rows)) | ✅ | 43.62 | 46.59 | 46.59 | 12 | 115686 | 5k 4-table joined records |
| HQ03 (4-Level Deep Entity Tree (Flight->Legs->Booking->Pass)) | ✅ | 4.84 | 5.28 | 5.28 | 10 | - | 4-level deep graph assembly |
| HQ04 (Account Relationship Graph with Optional Sub-Entities) | ✅ | 5.48 | 5.82 | 5.82 | 18 | - | Account graph with optional sub-entities |
| HQ05 (Fleet & Route Profitability Ledger (5 Tables, 400k+ Rows)) | ✅ | 405.70 | 429.75 | 429.75 | 20 | - | 5-table analytical ledger over 410k rows |
| HQ06 (Chained Multi-Stage CTEs (Hub Centrality & Degree)) | ✅ | 97.80 | 98.47 | 98.47 | 45 | - | 3 chained CTEs hub centrality over 112k flights |
| HQ07 (Correlated At-Capacity Subquery + Loyalty Cross-Check) | ✅ | 108.42 | 109.00 | 109.00 | 28 | - | Correlated subqueries in SELECT & WHERE |
| HQ08 (Recursive Multi-Hop Flight Connection Graph (1-3 Hops)) | ✅ | 309.32 | 319.53 | 319.53 | 40 | - | Recursive 1- to 3-hop itinerary graph traversal |
| HQ09 (Multi-Window Statistical Delay Dispersion & Cascades) | ✅ | 17.31 | 18.24 | 18.24 | 36 | - | 4 simultaneous window functions with framing |
| HQ10 (Keyset (Cursor) Pagination over Composite Key Under Load) | ✅ | 14.49 | 15.25 | 15.25 | 8 | - | Composite keyset cursor pagination |
| HQ11 (High-Dimensional Dynamic Faceted Flight Search Engine) | ✅ | 0.85 | 1.10 | 1.10 | 18 | - | Dynamic faceted search with 10 predicates |
| HQ12 (High-Volume Batch Upsert (2,500 Records ON CONFLICT)) | ✅ | 14.50 | 14.60 | 14.60 | 12 | - | High-volume 2,500 rows batch upsert |
| HQ13 (Optimistic Concurrency Bulk Fare & Status Adjustment) | ✅ | 0.28 | 0.33 | 0.33 | 6 | - | Optimistic version increment |
| HQ14 (High-Concurrency Seat Allocation Under Contention (C=100)) | ✅ | 0.98 | 1.16 | 1.16 | 16 | - | Concurrent seat reservation with FOR UPDATE |
| HQ15 (Distributed Financial / Points Transfer with 40001 Retry) | ✅ | 0.86 | 0.94 | 0.94 | 18 | - | Serializable points transfer with 40001 retry |
| HQ16 (Multi-Modal Hybrid Vector Similarity + BM25 RRF Search) | ✅ | 3.29 | 3.61 | 3.61 | 32 | - | Hybrid 384-dim HNSW + BM25 RRF search |

#### Deliberate Mistakes Diagnostics Summary:
```text
No diagnostic logs attached.
```

---

### PERSISTENT (Haskell)
- **Framework Version**: 2.18.1.0
- **Benchmark Timestamp**: 2026-11-15T00:00:00Z
- **Implementation Path**: `../persistent/persistent-postgres-air-bench`

#### Latency Distribution across Heavyweight Canonical Queries:
| Query | Status | p50 (ms) | p95 (ms) | p99 (ms) | LoC | Throughput | Notes |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| HQ01 (Massive Entity Deserialization (10k Wide Rows)) | ✅ | 99.02 | 105.33 | 105.33 | 3 | 103221 | 10k flight entities hydrated |
| HQ02 (Wide Multi-Join Composite Hydration (5k Joined Rows)) | ✅ | 141.32 | 158.59 | 158.59 | 12 | 35579 | 5k 4-table joined records |
| HQ03 (4-Level Deep Entity Tree (Flight->Legs->Booking->Pass)) | ✅ | 7.62 | 9.30 | 9.30 | 14 | - | 4-level deep graph assembly |
| HQ04 (Account Relationship Graph with Optional Sub-Entities) | ✅ | 7.77 | 11.04 | 11.04 | 18 | - | Account graph with optional sub-entities |
| HQ05 (Fleet & Route Profitability Ledger (5 Tables, 400k+ Rows)) | ✅ | 382.76 | 401.24 | 401.24 | 20 | - | 5-table analytical ledger over 410k rows |
| HQ06 (Chained Multi-Stage CTEs (Hub Centrality & Degree)) | ✅ | 90.47 | 90.60 | 90.60 | 45 | - | 3 chained CTEs hub centrality over 112k flights |
| HQ07 (Correlated At-Capacity Subquery + Loyalty Cross-Check) | ✅ | 103.59 | 104.23 | 104.23 | 28 | - | Correlated subqueries in SELECT & WHERE |
| HQ08 (Recursive Multi-Hop Flight Connection Graph (1-3 Hops)) | ✅ | 303.38 | 305.74 | 305.74 | 40 | - | Recursive 1- to 3-hop itinerary graph traversal |
| HQ09 (Multi-Window Statistical Delay Dispersion & Cascades) | ✅ | 21.67 | 24.14 | 24.14 | 36 | - | 4 simultaneous window functions with framing |
| HQ10 (Keyset (Cursor) Pagination over Composite Key Under Load) | ✅ | 13.63 | 13.91 | 13.91 | 5 | - | Composite keyset cursor pagination |
| HQ11 (High-Dimensional Dynamic Faceted Flight Search Engine) | ✅ | 1.05 | 1.21 | 1.21 | 18 | - | Dynamic faceted search with 10 predicates |
| HQ12 (High-Volume Batch Upsert (2,500 Records ON CONFLICT)) | ✅ | 9.15 | 9.46 | 9.46 | 12 | - | High-volume 2,500 rows batch upsert |
| HQ13 (Optimistic Concurrency Bulk Fare & Status Adjustment) | ✅ | 0.50 | 0.53 | 0.53 | 6 | - | Optimistic version increment |
| HQ14 (High-Concurrency Seat Allocation Under Contention (C=100)) | ✅ | 0.74 | 0.96 | 0.96 | 16 | - | Concurrent seat reservation with FOR UPDATE |
| HQ15 (Distributed Financial / Points Transfer with 40001 Retry) | ✅ | 0.69 | 0.75 | 0.75 | 18 | - | Serializable points transfer with 40001 retry |
| HQ16 (Multi-Modal Hybrid Vector Similarity + BM25 RRF Search) | ✅ | 3.54 | 3.81 | 3.81 | 32 | - | Hybrid 384-dim HNSW + BM25 RRF search |

#### Deliberate Mistakes Diagnostics Summary:
```text
No diagnostic logs attached.
```

---

### PRISMA (TypeScript)
- **Framework Version**: Node.js 26 / Prisma 6.19.3
- **Benchmark Timestamp**: 2026-11-15T15:32:43.559Z
- **Implementation Path**: `../prisma/bench`

#### Latency Distribution across Heavyweight Canonical Queries:
| Query | Status | p50 (ms) | p95 (ms) | p99 (ms) | LoC | Throughput | Notes |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| HQ01 (Massive Entity Deserialization (10k Wide Rows)) | ✅ | 48.05 | 52.00 | 52.00 | 6 | 208122 | 10k flight entities hydrated |
| HQ02 (Wide Multi-Join Composite Hydration (5k Joined Rows)) | ✅ | 9.36 | 11.71 | 11.71 | 14 | 533919 | 5k 4-table joined records |
| HQ03 (4-Level Deep Entity Tree (Flight->Legs->Booking->Pass)) | ✅ | 15.62 | 16.40 | 16.40 | 16 | - | 4-level deep graph assembly (0 N+1 batch loader) |
| HQ04 (Account Relationship Graph with Optional Sub-Entities) | ✅ | 6.79 | 7.75 | 7.75 | 18 | - | Account graph with nested includes |
| HQ05 (Fleet & Route Profitability Ledger (5 Tables, 400k+ Rows)) | ✅ | 716.12 | 872.37 | 872.37 | 24 | - | 5-table analytical ledger over 410k rows |
| HQ06 (Chained Multi-Stage CTEs (Hub Centrality & Degree)) | ✅ | 15.99 | 17.42 | 17.42 | 26 | - | 3 chained CTEs hub centrality over 112k flights |
| HQ07 (Correlated At-Capacity Subquery + Loyalty Cross-Check) | ✅ | 114.48 | 116.01 | 116.01 | 22 | - | Correlated subqueries in SELECT & WHERE |
| HQ08 (Recursive Multi-Hop Flight Connection Graph (1-3 Hops)) | ✅ | 60.20 | 185.96 | 185.96 | 25 | - | Recursive 1- to 3-hop itinerary graph traversal |
| HQ09 (Multi-Window Statistical Delay Dispersion & Cascades) | ✅ | 14.21 | 14.84 | 14.84 | 20 | - | 4 simultaneous window functions with framing |
| HQ10 (Keyset (Cursor) Pagination over Composite Key Under Load) | ✅ | 13.17 | 15.17 | 15.17 | 14 | - | Composite keyset cursor pagination |
| HQ11 (High-Dimensional Dynamic Faceted Flight Search Engine) | ✅ | 1.15 | 2.43 | 2.43 | 32 | - | Dynamic faceted search with 10 predicates |
| HQ12 (High-Volume Batch Upsert (2,500 Records ON CONFLICT)) | ✅ | 15.48 | 15.69 | 15.69 | 18 | - | Prisma 2,500 rows batch upsert |
| HQ13 (Optimistic Concurrency Bulk Fare & Status Adjustment) | ✅ | 0.58 | 0.86 | 0.86 | 12 | - | Optimistic version increment with updateMany |
| HQ14 (High-Concurrency Seat Allocation Under Contention (C=100)) | ✅ | 0.60 | 0.82 | 0.82 | 18 | 247 | Concurrent seat reservation with FOR UPDATE |
| HQ15 (Distributed Financial / Points Transfer with 40001 Retry) | ✅ | 1.25 | 1.38 | 1.38 | 22 | - | Serializable points transfer with 40001 retry |
| HQ16 (Multi-Modal Hybrid Vector Similarity + BM25 RRF Search) | ✅ | 5.53 | 5.81 | 5.81 | 22 | - | Hybrid 384-dim HNSW + BM25 RRF search |

#### Deliberate Mistakes Diagnostics Summary:
```text
No diagnostic logs attached.
```

---

### HASKELL-OPALEYE (Haskell)
- **Framework Version**: 0.10.8.0
- **Benchmark Timestamp**: 2026-11-15T00:00:00Z
- **Implementation Path**: `../haskell-opaleye/opaleye-postgres-air-bench`

#### Latency Distribution across Heavyweight Canonical Queries:
| Query | Status | p50 (ms) | p95 (ms) | p99 (ms) | LoC | Throughput | Notes |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| HQ01 (Massive Entity Deserialization (10k Wide Rows)) | ✅ | 101.22 | 105.29 | 105.29 | 6 | 101544 | 10k flight entities hydrated |
| HQ02 (Wide Multi-Join Composite Hydration (5k Joined Rows)) | ✅ | 139.94 | 147.00 | 147.00 | 10 | 35821 | 5k 4-table joined records |
| HQ03 (4-Level Deep Entity Tree (Flight->Legs->Booking->Pass)) | ✅ | 63.50 | 67.03 | 67.03 | 14 | - | 4-level deep graph assembly (0 N+1) |
| HQ04 (Account Relationship Graph with Optional Sub-Entities) | ✅ | 11.13 | 11.86 | 11.86 | 18 | - | Account graph with optional sub-entities |
| HQ05 (Fleet & Route Profitability Ledger (5 Tables, 400k+ Rows)) | ✅ | 363.87 | 380.11 | 380.11 | 20 | - | 5-table analytical ledger over 410k rows |
| HQ06 (Chained Multi-Stage CTEs (Hub Centrality & Degree)) | ✅ | 86.50 | 87.21 | 87.21 | 45 | - | 3 chained CTEs hub centrality over 112k flights |
| HQ07 (Correlated At-Capacity Subquery + Loyalty Cross-Check) | ✅ | 102.50 | 105.67 | 105.67 | 28 | - | Correlated subqueries in SELECT & WHERE |
| HQ08 (Recursive Multi-Hop Flight Connection Graph (1-3 Hops)) | ✅ | 300.70 | 313.20 | 313.20 | 40 | - | Recursive 1- to 3-hop itinerary graph traversal |
| HQ09 (Multi-Window Statistical Delay Dispersion & Cascades) | ✅ | 16.36 | 16.72 | 16.72 | 36 | - | 4 simultaneous window functions with framing |
| HQ10 (Keyset (Cursor) Pagination over Composite Key Under Load) | ✅ | 12.07 | 12.77 | 12.77 | 8 | - | Composite keyset cursor pagination |
| HQ11 (High-Dimensional Dynamic Faceted Flight Search Engine) | ✅ | 9.13 | 9.45 | 9.45 | 34 | - | Dynamic faceted search with 10 predicates |
| HQ12 (High-Volume Batch Upsert (2,500 Records ON CONFLICT)) | ✅ | 23.59 | 24.17 | 24.17 | 12 | - | High-volume 2,500 rows batch upsert |
| HQ13 (Optimistic Concurrency Bulk Fare & Status Adjustment) | ✅ | 0.18 | 0.20 | 0.20 | 8 | - | Optimistic version increment |
| HQ14 (High-Concurrency Seat Allocation Under Contention (C=100)) | ✅ | 0.77 | 1.00 | 1.00 | 16 | - | Concurrent seat reservation with FOR UPDATE |
| HQ15 (Distributed Financial / Points Transfer with 40001 Retry) | ✅ | 0.82 | 0.94 | 0.94 | 20 | - | Serializable points transfer with 40001 retry |
| HQ16 (Multi-Modal Hybrid Vector Similarity + BM25 RRF Search) | ✅ | 3.07 | 3.40 | 3.40 | 32 | - | Hybrid 384-dim HNSW + BM25 RRF search |

#### Deliberate Mistakes Diagnostics Summary:
```text
No diagnostic logs attached.
```

---

### BEAM (Haskell)
- **Framework Version**: 0.11.2.0
- **Benchmark Timestamp**: 2026-11-15T00:00:00Z
- **Implementation Path**: `../beam/beam-postgres-air-bench`

#### Latency Distribution across Heavyweight Canonical Queries:
| Query | Status | p50 (ms) | p95 (ms) | p99 (ms) | LoC | Throughput | Notes |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| HQ01 (Massive Entity Deserialization (10k Wide Rows)) | ✅ | 89.28 | 96.05 | 96.05 | 6 | 113504 | 10k flight entities hydrated |
| HQ02 (Wide Multi-Join Composite Hydration (5k Joined Rows)) | ✅ | 94.85 | 102.37 | 102.37 | 10 | 53757 | 5k 4-table joined records |
| HQ03 (4-Level Deep Entity Tree (Flight->Legs->Booking->Pass)) | ✅ | 44.73 | 52.48 | 52.48 | 18 | 49367 | 4-level deep graph assembly (0 N+1) |
| HQ04 (Account Relationship Graph with Optional Sub-Entities) | ✅ | 55.16 | 56.35 | 56.35 | 22 | - | Account graph with 7,000 joined records |
| HQ05 (Fleet & Route Profitability Ledger (5 Tables, 400k+ Rows)) | ✅ | 350.37 | 365.33 | 365.33 | 25 | - | 5-table analytical ledger over 410k rows |
| HQ06 (Chained Multi-Stage CTEs (Hub Centrality & Degree)) | ✅ | 87.23 | 87.77 | 87.77 | 28 | - | 3 chained CTEs hub centrality over 112k flights |
| HQ07 (Correlated At-Capacity Subquery + Loyalty Cross-Check) | ✅ | 100.52 | 101.34 | 101.34 | 22 | - | Correlated subqueries in SELECT & WHERE |
| HQ08 (Recursive Multi-Hop Flight Connection Graph (1-3 Hops)) | ✅ | 300.52 | 301.59 | 301.59 | 24 | - | Recursive 1- to 3-hop itinerary graph traversal |
| HQ09 (Multi-Window Statistical Delay Dispersion & Cascades) | ✅ | 17.20 | 18.14 | 18.14 | 20 | - | 4 simultaneous window functions with framing |
| HQ10 (Keyset (Cursor) Pagination over Composite Key Under Load) | ✅ | 11.98 | 13.57 | 18.60 | 8 | - | Composite keyset cursor pagination |
| HQ11 (High-Dimensional Dynamic Faceted Flight Search Engine) | ✅ | 1.04 | 1.33 | 1.38 | 26 | - | Dynamic faceted search with 10 predicates |
| HQ12 (High-Volume Batch Upsert (2,500 Records ON CONFLICT)) | ✅ | 27.10 | 28.30 | 28.30 | 14 | - | Beam insertOnConflict 2,500 rows batch |
| HQ13 (Optimistic Concurrency Bulk Fare & Status Adjustment) | ✅ | 0.24 | 0.28 | 0.28 | 8 | - | Optimistic version increment |
| HQ14 (High-Concurrency Seat Allocation Under Contention (C=100)) | ✅ | 0.43 | 0.50 | 0.50 | 16 | 234 | Concurrent seat reservation with FOR UPDATE |
| HQ15 (Distributed Financial / Points Transfer with 40001 Retry) | ✅ | 1.16 | 5.54 | 5.54 | 18 | - | Serializable points transfer with 40001 retry |
| HQ16 (Multi-Modal Hybrid Vector Similarity + BM25 RRF Search) | ✅ | 5.03 | 9.06 | 9.06 | 20 | - | Hybrid 384-dim HNSW + BM25 RRF search |

#### Deliberate Mistakes Diagnostics Summary:
```text
No diagnostic logs attached.
```

---

### ESQUELETO (Haskell)
- **Framework Version**: 3.6.0.3
- **Benchmark Timestamp**: 2026-11-15 04:43:42.408112 UTC
- **Implementation Path**: `../esqueleto/esqueleto-postgres-air-bench`

#### Latency Distribution across Heavyweight Canonical Queries:
| Query | Status | p50 (ms) | p95 (ms) | p99 (ms) | LoC | Throughput | Notes |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| HQ01 (Massive Entity Deserialization (10k Wide Rows)) | ✅ | 118.33 | 129.78 | 129.78 | 7 | 85377 | 10k flight entities hydrated |
| HQ02 (Wide Multi-Join Composite Hydration (5k Joined Rows)) | ✅ | 164.54 | 170.28 | 170.28 | 14 | 30759 | 5k 4-table joined records |
| HQ03 (4-Level Deep Entity Tree (Flight->Legs->Booking->Pass)) | ✅ | 76.17 | 87.27 | 87.27 | 16 | 28989 | 4-level deep graph assembly (0 N+1) |
| HQ04 (Account Relationship Graph with Optional Sub-Entities) | ✅ | 15.89 | 16.66 | 16.66 | 18 | - | Account graph with 7,000 joined records |
| HQ05 (Fleet & Route Profitability Ledger (5 Tables, 400k+ Rows)) | ✅ | 350.84 | 354.10 | 354.10 | 24 | - | 5-table analytical ledger over 410k rows |
| HQ06 (Chained Multi-Stage CTEs (Hub Centrality & Degree)) | ✅ | 87.41 | 88.86 | 88.86 | 28 | - | 3 chained CTEs hub centrality over 112k flights |
| HQ07 (Correlated At-Capacity Subquery + Loyalty Cross-Check) | ✅ | 101.27 | 102.71 | 102.71 | 22 | - | Correlated subqueries in SELECT & WHERE |
| HQ08 (Recursive Multi-Hop Flight Connection Graph (1-3 Hops)) | ✅ | 297.85 | 302.85 | 302.85 | 24 | - | Recursive 1- to 3-hop itinerary graph traversal |
| HQ09 (Multi-Window Statistical Delay Dispersion & Cascades) | ✅ | 22.86 | 24.73 | 24.73 | 20 | - | 4 simultaneous window functions with framing |
| HQ10 (Keyset (Cursor) Pagination over Composite Key Under Load) | ✅ | 13.56 | 15.18 | 15.18 | 9 | - | Composite keyset cursor pagination |
| HQ11 (High-Dimensional Dynamic Faceted Flight Search Engine) | ✅ | 1.51 | 1.68 | 1.68 | 28 | - | Dynamic faceted search with 10 predicates |
| HQ12 (High-Volume Batch Upsert (2,500 Records ON CONFLICT)) | ✅ | 9.92 | 10.43 | 10.43 | 16 | - | Esqueleto on_conflict 2,500 rows batch upsert |
| HQ13 (Optimistic Concurrency Bulk Fare & Status Adjustment) | ✅ | 3.41 | 3.62 | 3.62 | 10 | - | Optimistic version increment |
| HQ14 (High-Concurrency Seat Allocation Under Contention (C=100)) | ✅ | 1.01 | 1.07 | 1.07 | 16 | 244 | Concurrent seat reservation with FOR UPDATE |
| HQ15 (Distributed Financial / Points Transfer with 40001 Retry) | ✅ | 1.28 | 1.35 | 1.35 | 18 | - | Serializable points transfer with 40001 retry |
| HQ16 (Multi-Modal Hybrid Vector Similarity + BM25 RRF Search) | ✅ | 3.78 | 3.94 | 3.94 | 20 | - | Hybrid 384-dim HNSW + BM25 RRF search |

#### Deliberate Mistakes Diagnostics Summary:
```text
No diagnostic logs attached.
```

---

### RAILS (Ruby)
- **Framework Version**: Ruby 4.0.9 / ActiveRecord 8.1.4.1
- **Benchmark Timestamp**: 2026-11-15T15:40:49Z
- **Implementation Path**: `../rails/bench`

#### Latency Distribution across Heavyweight Canonical Queries:
| Query | Status | p50 (ms) | p95 (ms) | p99 (ms) | LoC | Throughput | Notes |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| HQ01 (Massive Entity Deserialization (10k Wide Rows)) | ✅ | 111.37 | 115.09 | 115.09 | 4 | 89792 | 10k flight entities hydrated |
| HQ02 (Wide Multi-Join Composite Hydration (5k Joined Rows)) | ✅ | 17.66 | 27.97 | 27.97 | 14 | 283126 | 5k 4-table joined records |
| HQ03 (4-Level Deep Entity Tree (Flight->Legs->Booking->Pass)) | ✅ | 25.47 | 30.14 | 30.14 | 6 | - | 4-level deep graph assembly with includes (0 N+1) |
| HQ04 (Account Relationship Graph with Optional Sub-Entities) | ✅ | 8.84 | 12.72 | 12.72 | 6 | - | Account graph with nested includes |
| HQ05 (Fleet & Route Profitability Ledger (5 Tables, 400k+ Rows)) | ✅ | 716.52 | 719.93 | 719.93 | 24 | - | 5-table analytical ledger over 410k rows |
| HQ06 (Chained Multi-Stage CTEs (Hub Centrality & Degree)) | ✅ | 15.98 | 16.08 | 16.08 | 26 | - | 3 chained CTEs hub centrality over 112k flights |
| HQ07 (Correlated At-Capacity Subquery + Loyalty Cross-Check) | ✅ | 106.47 | 107.48 | 107.48 | 22 | - | Correlated subqueries in SELECT & WHERE |
| HQ08 (Recursive Multi-Hop Flight Connection Graph (1-3 Hops)) | ✅ | 261.36 | 298.55 | 298.55 | 25 | - | Recursive 1- to 3-hop itinerary graph traversal |
| HQ09 (Multi-Window Statistical Delay Dispersion & Cascades) | ✅ | 2.30 | 2.60 | 2.60 | 20 | - | 4 simultaneous window functions with framing |
| HQ10 (Keyset (Cursor) Pagination over Composite Key Under Load) | ✅ | 12.77 | 13.50 | 13.50 | 6 | - | Composite keyset cursor pagination |
| HQ11 (High-Dimensional Dynamic Faceted Flight Search Engine) | ✅ | 1.28 | 4.60 | 4.60 | 16 | - | Dynamic faceted search with 10 predicates |
| HQ12 (High-Volume Batch Upsert (2,500 Records ON CONFLICT)) | ✅ | 7.86 | 8.58 | 8.58 | 16 | - | ActiveRecord 2,500 rows batch upsert |
| HQ13 (Optimistic Concurrency Bulk Fare & Status Adjustment) | ✅ | 0.28 | 0.30 | 0.30 | 4 | - | Optimistic version increment with update_all |
| HQ14 (High-Concurrency Seat Allocation Under Contention (C=100)) | ✅ | 0.59 | 0.66 | 0.66 | 8 | 228 | Concurrent seat allocation with lock("FOR UPDATE") |
| HQ15 (Distributed Financial / Points Transfer with 40001 Retry) | ✅ | 1.26 | 1.32 | 1.32 | 18 | - | Serializable points transfer with retry |
| HQ16 (Multi-Modal Hybrid Vector Similarity + BM25 RRF Search) | ✅ | 5.65 | 5.87 | 5.87 | 22 | - | Hybrid 384-dim HNSW + BM25 RRF search |

#### Deliberate Mistakes Diagnostics Summary:
```text
No diagnostic logs attached.
```

---

### REL8 (Haskell)
- **Framework Version**: 1.8.0.0
- **Benchmark Timestamp**: 2026-11-15 16:12:17.206275 UTC
- **Implementation Path**: `../rel8/rel8-postgres-air-bench`

#### Latency Distribution across Heavyweight Canonical Queries:
| Query | Status | p50 (ms) | p95 (ms) | p99 (ms) | LoC | Throughput | Notes |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| HQ01 (Massive Entity Deserialization (10k Wide Rows)) | ✅ | 81.51 | 83.50 | 83.50 | 6 | 122678 | 10k flight entities hydrated |
| HQ02 (Wide Multi-Join Composite Hydration (5k Joined Rows)) | ✅ | 409.04 | 868.39 | 868.39 | 14 | 12224 | 5k 4-table joined records |
| HQ03 (4-Level Deep Entity Tree (Flight->Legs->Booking->Pass)) | ✅ | 8.82 | 9.14 | 9.14 | 20 | - | 4-level deep graph assembly with optional joins |
| HQ04 (Account Relationship Graph with Optional Sub-Entities) | ✅ | 0.39 | 0.51 | 0.51 | 18 | - | Account graph assembly |
| HQ05 (Fleet & Route Profitability Ledger (5 Tables, 400k+ Rows)) | ✅ | 730.40 | 741.16 | 741.16 | 24 | - | 5-table analytical ledger over 410k rows |
| HQ06 (Chained Multi-Stage CTEs (Hub Centrality & Degree)) | ✅ | 15.81 | 15.87 | 15.87 | 26 | - | 3 chained CTEs hub centrality over 112k flights |
| HQ07 (Correlated At-Capacity Subquery + Loyalty Cross-Check) | ✅ | 107.28 | 113.32 | 113.32 | 22 | - | Correlated subqueries in SELECT & WHERE |
| HQ08 (Recursive Multi-Hop Flight Connection Graph (1-3 Hops)) | ✅ | 251.77 | 253.86 | 253.86 | 25 | - | Recursive 1- to 3-hop itinerary graph traversal |
| HQ09 (Multi-Window Statistical Delay Dispersion & Cascades) | ✅ | 1.80 | 2.05 | 2.05 | 20 | - | 4 simultaneous window functions with framing |
| HQ10 (Keyset (Cursor) Pagination over Composite Key Under Load) | ✅ | 11.90 | 12.34 | 12.34 | 10 | - | Composite keyset cursor pagination |
| HQ11 (High-Dimensional Dynamic Faceted Flight Search Engine) | ✅ | 1.05 | 1.48 | 1.48 | 28 | - | Dynamic faceted search with 10 predicates |
| HQ12 (High-Volume Batch Upsert (2,500 Records ON CONFLICT)) | ✅ | 7.48 | 7.93 | 7.93 | 16 | - | Rel8 2,500 rows batch upsert |
| HQ13 (Optimistic Concurrency Bulk Fare & Status Adjustment) | ✅ | 0.19 | 0.25 | 0.25 | 8 | - | Optimistic version increment |
| HQ14 (High-Concurrency Seat Allocation Under Contention (C=100)) | ✅ | 0.63 | 0.70 | 0.70 | 14 | 244 | Concurrent seat allocation with FOR UPDATE |
| HQ15 (Distributed Financial / Points Transfer with 40001 Retry) | ✅ | 0.73 | 0.77 | 0.77 | 20 | - | Serializable points transfer with 40001 retry |
| HQ16 (Multi-Modal Hybrid Vector Similarity + BM25 RRF Search) | ✅ | 5.54 | 5.77 | 5.77 | 20 | - | Hybrid 384-dim HNSW + BM25 RRF search |

#### Deliberate Mistakes Diagnostics Summary:
```text
No diagnostic logs attached.
```

---

### SQUEAL (Haskell)
- **Framework Version**: 0.9.2.0
- **Benchmark Timestamp**: 2026-11-15 17:27:30.195765 UTC
- **Implementation Path**: `../squeal/squeal-postgres-air-bench`

#### Latency Distribution across Heavyweight Canonical Queries:
| Query | Status | p50 (ms) | p95 (ms) | p99 (ms) | LoC | Throughput | Notes |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| HQ01 (Massive Entity Deserialization (10k Wide Rows)) | ✅ | 654.84 | 668.66 | 668.66 | 6 | 15271 | 10k flight entities hydrated |
| HQ02 (Wide Multi-Join Composite Hydration (5k Joined Rows)) | ✅ | 1039.86 | 1191.14 | 1191.14 | 28 | 4808 | 5k 4-table joined records |
| HQ03 (4-Level Deep Entity Tree (Flight->Legs->Booking->Pass)) | ✅ | 1.17 | 2.11 | 2.11 | 24 | - | 4-level deep graph assembly with optional joins |
| HQ04 (Account Relationship Graph with Optional Sub-Entities) | ✅ | 0.43 | 0.85 | 0.85 | 6 | - | Account graph assembly |
| HQ05 (Fleet & Route Profitability Ledger (5 Tables, 400k+ Rows)) | ✅ | 730.49 | 732.04 | 732.04 | 18 | - | 5-table analytical ledger over 410k rows |
| HQ06 (Chained Multi-Stage CTEs (Hub Centrality & Degree)) | ✅ | 15.68 | 15.94 | 15.94 | 20 | - | 3 chained CTEs hub centrality over 112k flights |
| HQ07 (Correlated At-Capacity Subquery + Loyalty Cross-Check) | ✅ | 106.34 | 111.59 | 111.59 | 16 | - | Correlated subqueries in SELECT & WHERE |
| HQ08 (Recursive Multi-Hop Flight Connection Graph (1-3 Hops)) | ✅ | 238.69 | 239.76 | 239.76 | 20 | - | Recursive 1- to 3-hop itinerary graph traversal |
| HQ09 (Multi-Window Statistical Delay Dispersion & Cascades) | ✅ | 1.80 | 1.91 | 1.91 | 18 | - | 4 simultaneous window functions with framing |
| HQ10 (Keyset (Cursor) Pagination over Composite Key Under Load) | ✅ | 11.84 | 12.82 | 12.82 | 8 | - | Composite keyset cursor pagination |
| HQ11 (High-Dimensional Dynamic Faceted Flight Search Engine) | ✅ | 0.32 | 0.37 | 0.37 | 20 | - | Dynamic faceted search with 10 predicates |
| HQ12 (High-Volume Batch Upsert (2,500 Records ON CONFLICT)) | ✅ | 7.57 | 7.71 | 7.71 | 12 | - | Squeal 2,500 rows batch upsert |
| HQ13 (Optimistic Concurrency Bulk Fare & Status Adjustment) | ✅ | 0.19 | 0.26 | 0.26 | 8 | - | Optimistic version increment |
| HQ14 (High-Concurrency Seat Allocation Under Contention (C=100)) | ✅ | 0.64 | 0.74 | 0.74 | 12 | 227 | Concurrent seat allocation with FOR UPDATE |
| HQ15 (Distributed Financial / Points Transfer with 40001 Retry) | ✅ | 0.78 | 0.92 | 0.92 | 10 | - | Serializable points transfer with 40001 retry |
| HQ16 (Multi-Modal Hybrid Vector Similarity + BM25 RRF Search) | ✅ | 5.54 | 5.61 | 5.61 | 18 | - | Hybrid 384-dim HNSW + BM25 RRF search |

#### Deliberate Mistakes Diagnostics Summary:
```text
No diagnostic logs attached.
```

---

