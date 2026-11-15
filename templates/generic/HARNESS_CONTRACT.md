# Universal ORM Benchmark Harness Contract

This document defines the interface and data schema that any ORM implementation harness (Rust, Go, Python, Java, C#, Ruby, Elixir) must adhere to for automatic ingestion into `BENCHMARK_REPORT.md`.

---

## 1. Input Environment

Every benchmark harness expects:
- **Database URL**: `postgresql://postgres:postgres@localhost:5434/postgres_air`
- **Default Schema Search Path**: `postgres_air, public`
- **Pool Size**: 20 connections

---

## 2. Benchmark Protocol Steps

Each ORM implementation directory should contain a script `run_bench.sh` that executes:
1. **Compilation / Warmup**: Priming connection pools and running 50 warmup iterations per canonical query.
2. **Canonical Query Benchmarks (Q01–Q15)**:
   - For each query, execute 500 iterations.
   - Record $p_{50}$, $p_{95}$, $p_{99}$ latency in milliseconds.
3. **Concurrency Stress Test**:
   - Run 1,000 transactions at concurrency $C=50$.
   - Record aggregate throughput (requests/sec).
4. **Memory / Allocations**:
   - Total megabytes allocated across the run.
   - Max resident set size (RSS) or peak live heap.
   - Major GC cycles or pause durations.
5. **Ergonomics & Blast Radius**:
   - Lines of code (excluding comments/blanks) for Q01–Q15.
   - AST token count.
   - Count of unique non-standard operators/combinators.
   - Diff lines resulting from adding `flight_category` column to `Flight`.
6. **Deliberate Mistakes UX (E01–E10)**:
   - Compile 10 intentionally broken query files.
   - Measure diagnostic line count and verify zero framework type leakage.

---

## 3. Output Schema (`bench/results/<orm_name>.json`)

The benchmark harness must emit (or use `runner/metrics_collector.py` to write) a JSON file at `bench/results/<orm_name>.json` matching this schema:

```json
{
  "orm": "rel8",
  "language": "Haskell",
  "version": "1.4.1",
  "timestamp": "2026-11-14T22:00:00Z",
  "summary": {
    "overall_score": 88.5,
    "avg_p95_ms": 1.45,
    "peak_rps": 4250,
    "heap_mb_per_query": 0.12,
    "blast_radius_lines": 4,
    "mistake_score": 9
  },
  "canonical_queries": {
    "Q01": {
      "status": "✅",
      "p50_ms": 0.42,
      "p95_ms": 0.85,
      "p99_ms": 1.20,
      "loc": 6,
      "notes": "Native point lookup"
    },
    "Q02": { ... },
    ...
    "Q15": { ... }
  },
  "ergonomics": {
    "loc": 142,
    "tokens": 820,
    "unique_operators": 4,
    "operator_score": 9.0,
    "blast_radius_lines": 4,
    "blast_radius_files": 1
  },
  "deliberate_mistakes": {
    "E01": { "line_count": 6, "zero_leakage": true },
    "E02": { "line_count": 8, "zero_leakage": true },
    ...
    "E10": { "line_count": 5, "zero_leakage": true }
  },
  "performance": {
    "peak_rps": 4250.0,
    "total_allocated_mb": 145.2,
    "max_heap_mb": 28.5,
    "gc_major_collections": 14,
    "gc_pause_total_ms": 3.2
  }
}
```

---

## 4. Automatic Report Ingestion

Once `bench/results/<orm_name>.json` is written, running:
```bash
python3 bench/runner/report_generator.py
```
automatically updates `BENCHMARK_REPORT.md` with:
- The updated leaderboard ranking.
- The 15 canonical queries scorecard matrix.
- Quantitative ergonomics comparison.
- Compiler error UX scorecard.
- The complete detailed breakdown section.
