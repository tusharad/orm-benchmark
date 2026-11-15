#!/usr/bin/env python3
"""
Report Generator for Postgres Air ORM Benchmarks
Reads JSON result files from bench/results/<orm>.json and regenerates or updates
the master BENCHMARK_REPORT.md document with rankings, matrices, and per-ORM breakdowns.
"""

import json
import os
import sys
from pathlib import Path

BENCH_DIR = Path(__file__).resolve().parent.parent
RESULTS_DIR = BENCH_DIR / "results"
REPORT_PATH = BENCH_DIR / "BENCHMARK_REPORT.md"

HEAVY_QUERIES = [
    ("HQ01", "Massive Entity Deserialization (10k Wide Rows)"),
    ("HQ02", "Wide Multi-Join Composite Hydration (5k Joined Rows)"),
    ("HQ03", "4-Level Deep Entity Tree (Flight->Legs->Booking->Pass)"),
    ("HQ04", "Account Relationship Graph with Optional Sub-Entities"),
    ("HQ05", "Fleet & Route Profitability Ledger (5 Tables, 400k+ Rows)"),
    ("HQ06", "Chained Multi-Stage CTEs (Hub Centrality & Degree)"),
    ("HQ07", "Correlated At-Capacity Subquery + Loyalty Cross-Check"),
    ("HQ08", "Recursive Multi-Hop Flight Connection Graph (1-3 Hops)"),
    ("HQ09", "Multi-Window Statistical Delay Dispersion & Cascades"),
    ("HQ10", "Keyset (Cursor) Pagination over Composite Key Under Load"),
    ("HQ11", "High-Dimensional Dynamic Faceted Flight Search Engine"),
    ("HQ12", "High-Volume Batch Upsert (2,500 Records ON CONFLICT)"),
    ("HQ13", "Optimistic Concurrency Bulk Fare & Status Adjustment"),
    ("HQ14", "High-Concurrency Seat Allocation Under Contention (C=100)"),
    ("HQ15", "Distributed Financial / Points Transfer with 40001 Retry"),
    ("HQ16", "Multi-Modal Hybrid Vector Similarity + BM25 RRF Search"),
]

DELIBERATE_MISTAKES = [
    ("E01", "Type Mismatch in Equality"),
    ("E02", "Key Mismatch in Join"),
    ("E03", "Missing GROUP BY Column"),
    ("E04", "IO Escape inside Pure Transaction"),
    ("E05", "Nullability Constraint Violation"),
    ("E06", "Unknown Column Selection"),
    ("E07", "Window Function in WHERE Clause"),
    ("E08", "Dangling Join / Unbound Table Alias"),
    ("E09", "Mutation of Immutable Primary Key"),
    ("E10", "Inner Query Scope Leakage"),
]

def load_results():
    results = {}
    if not RESULTS_DIR.exists():
        return results
    for f in RESULTS_DIR.glob("*.json"):
        try:
            with open(f, "r") as fp:
                data = json.load(fp)
                orm_name = data.get("orm", f.stem)
                results[orm_name] = data
        except Exception as e:
            print(f"Error loading {f}: {e}", file=sys.stderr)
    return results

def format_num(val, unit="", precision=2):
    if val is None or val == "-":
        return "-"
    if isinstance(val, (int, float)):
        return f"{val:.{precision}f}{unit}"
    return str(val)

def generate_report():
    results = load_results()
    
    # Sort results by overall score or p95 latency
    sorted_orms = sorted(
        results.keys(),
        key=lambda k: results[k].get("summary", {}).get("overall_score", 0),
        reverse=True
    )
    
    report_lines = [
        "# Postgres Air Heavyweight ORM Benchmark Combined Report",
        "",
        f"> **Total Evaluated ORMs**: {len(sorted_orms)}  ",
        "> **Target Database**: PostgreSQL 17 (`postgres_air`, 78+ Million Rows)  ",
        "> **Host**: Docker `localhost:5434`  ",
        "> **Evaluated Stress Dimensions**: Massive Deserialization & GC Pressure, Deep Entity Trees (N+1 Prevention), Multi-Table Analytical Ledgers, Chained & Recursive CTEs, Advanced Multi-Window Analytics, Dynamic Query DSL Composition, High-Volume Upserts, Concurrency Contention ($C=100$), Quantitative Ergonomics, and Compiler Error UX.",
        "",
        "---",
        "",
        "## 1. Overall Executive Leaderboard",
        "",
        "| Rank | ORM | Language | Overall Score | Passed (HQ01–16) | Avg p95 Latency | Peak RPS ($C=50$) | Hydration Speed | Max Heap RSS | Blast Radius | Compiler UX |",
        "| :---: | :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |"
    ]
    
    if not sorted_orms:
        report_lines.append("| - | *No benchmarks executed yet* | - | - | - | - | - | - | - | - | - |")
    else:
        for idx, orm in enumerate(sorted_orms, 1):
            data = results[orm]
            s = data.get("summary", {})
            report_lines.append(
                f"| {idx} | **{orm}** | {data.get('language', '-')} | "
                f"**{s.get('overall_score', '-')}** | "
                f"{s.get('passed_queries', 0)}/{s.get('total_queries', 16)} | "
                f"{format_num(s.get('avg_p95_ms'), ' ms')} | "
                f"{format_num(s.get('peak_rps'), ' ops/s', 0)} | "
                f"{format_num(s.get('hydration_rows_sec'), ' rows/s', 0)} | "
                f"{format_num(s.get('max_heap_mb'), ' MB')} | "
                f"{s.get('blast_radius_lines', '-')} lines | "
                f"{s.get('mistake_score', '-')}/10 |"
            )
            
    report_lines.extend([
        "",
        "---",
        "",
        "## 2. The 16 Heavyweight Canonical Queries Scorecard",
        "",
        "Status: ✅ = Native Typed Pass, ⚠️ = Workaround / Dynamic Fallback, ❌ = Failed / Unsupported, ⏳ = Pending.",
        ""
    ])
    
    # Table header
    q_cols = ["Query ID", "Description"] + (sorted_orms if sorted_orms else ["Example ORM"])
    report_lines.append("| " + " | ".join(q_cols) + " |")
    report_lines.append("| " + " | ".join([":---" if i < 2 else ":---:" for i in range(len(q_cols))]) + " |")
    
    for q_id, q_desc in HEAVY_QUERIES:
        row = [f"**{q_id}**", q_desc]
        if not sorted_orms:
            row.append("-")
        else:
            for orm in sorted_orms:
                q_status = results[orm].get("canonical_queries", {}).get(q_id, {}).get("status", "⏳")
                row.append(q_status)
        report_lines.append("| " + " | ".join(row) + " |")
        
    report_lines.extend([
        "",
        "---",
        "",
        "## 3. Large-Scale Hydration, Memory & GC Pressure Profile",
        "",
        "Measures decoding overhead, heap allocation rate, and garbage collection pressure when deserializing large datasets into native language records/structs.",
        "",
        "| ORM | HQ01 10k Rows (p95 ms) | HQ02 5k Joined (p95 ms) | Hydration Throughput | Total Allocated (MB) | Peak Heap RSS (MB) | Minor GC Pauses | Major GC Pauses | Total GC Pause (ms) |",
        "| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |"
    ])
    
    if not sorted_orms:
        report_lines.append("| - | - | - | - | - | - | - | - | - |")
    else:
        for orm in sorted_orms:
            perf = results[orm].get("performance", {})
            q = results[orm].get("canonical_queries", {})
            hyd = results[orm].get("hydration_benchmarks", {}).get("HQ01", {})
            report_lines.append(
                f"| **{orm}** | "
                f"{format_num(q.get('HQ01', {}).get('p95_ms'), ' ms')} | "
                f"{format_num(q.get('HQ02', {}).get('p95_ms'), ' ms')} | "
                f"{format_num(hyd.get('rows_per_sec'), ' rows/s', 0)} | "
                f"{format_num(perf.get('total_allocated_mb'), ' MB')} | "
                f"{format_num(perf.get('max_heap_mb'), ' MB')} | "
                f"{perf.get('gc_minor_collections', '-')} | "
                f"{perf.get('gc_major_collections', '-')} | "
                f"{format_num(perf.get('gc_pause_total_ms'), ' ms')} |"
            )

    report_lines.extend([
        "",
        "---",
        "",
        "## 4. Application-Level Concurrency & Scalability Ladder",
        "",
        "Measures throughput and tail latencies across increasing concurrency levels ($C \\in \\{1, 10, 50, 100\\}$) on a standardized 20-connection pool.",
        "",
        "| ORM | $C=1$ (RPS / p99) | $C=10$ (RPS / p99) | $C=50$ (RPS / p99) | $C=100$ (RPS / p99) | HQ14 Contention RPS | HQ14 Tail p99.9 | Contention Falloff % |",
        "| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |"
    ])

    if not sorted_orms:
        report_lines.append("| - | - | - | - | - | - | - | - |")
    else:
        for orm in sorted_orms:
            conc = results[orm].get("concurrency_benchmarks", {})
            c1 = conc.get("C1", {})
            c10 = conc.get("C10", {})
            c50 = conc.get("C50", {})
            c100 = conc.get("C100", {})
            q14 = results[orm].get("canonical_queries", {}).get("HQ14", {})
            
            c1_str = f"{format_num(c1.get('rps'), precision=0)} / {format_num(c1.get('p99_ms'), 'ms')}" if c1 else "-"
            c10_str = f"{format_num(c10.get('rps'), precision=0)} / {format_num(c10.get('p99_ms'), 'ms')}" if c10 else "-"
            c50_str = f"{format_num(c50.get('rps'), precision=0)} / {format_num(c50.get('p99_ms'), 'ms')}" if c50 else "-"
            c100_str = f"{format_num(c100.get('rps'), precision=0)} / {format_num(c100.get('p99_ms'), 'ms')}" if c100 else "-"
            
            report_lines.append(
                f"| **{orm}** | {c1_str} | {c10_str} | {c50_str} | {c100_str} | "
                f"{format_num(q14.get('rows_per_sec'), ' ops/s', 0)} | "
                f"{format_num(q14.get('p99_ms'), ' ms')} | "
                f"- |"
            )

    report_lines.extend([
        "",
        "---",
        "",
        "## 5. Quantitative Ergonomics & Expressiveness",
        "",
        "| ORM | Query LoC (Total HQ01–HQ16) | AST Token Count | Unique DSL Operators | Operator Complexity Score | Schema Blast Radius (Lines changed) | Files Changed |",
        "| :--- | :---: | :---: | :---: | :---: | :---: | :---: |"
    ])
    
    if not sorted_orms:
        report_lines.append("| - | - | - | - | - | - | - |")
    else:
        for orm in sorted_orms:
            ergo = results[orm].get("ergonomics", {})
            report_lines.append(
                f"| **{orm}** | {ergo.get('loc', '-')} | "
                f"{ergo.get('tokens', '-')} | "
                f"{ergo.get('unique_operators', '-')} | "
                f"{ergo.get('operator_score', '-')} | "
                f"{ergo.get('blast_radius_lines', '-')} | "
                f"{ergo.get('blast_radius_files', '-')} |"
            )
            
    report_lines.extend([
        "",
        "---",
        "",
        "## 6. The Deliberate Mistake Suite (Compiler Error UX)",
        "",
        "Scoring: `Lines` = Diagnostic lines emitted by compiler; `Leakage` = **Zero** (mentions only user types) vs **Leaked** (internal library plumbing leaked).",
        "",
        "| Mistake Scenario | Metric | " + " | ".join([f"**{o}**" for o in sorted_orms] if sorted_orms else ["Example ORM"]) + " |",
        "| :--- | :--- | " + " | ".join([":---:" for _ in (sorted_orms if sorted_orms else [""])]) + " |"
    ])
    
    for e_id, e_name in DELIBERATE_MISTAKES:
        row = [f"**{e_id}: {e_name}**", "Lines / Leakage"]
        if not sorted_orms:
            row.append("-")
        else:
            for orm in sorted_orms:
                m_info = results[orm].get("deliberate_mistakes", {}).get(e_id, {})
                lines = m_info.get("line_count", "-")
                leak = "Zero" if m_info.get("zero_leakage") else "Leaked" if m_info.get("zero_leakage") is False else "-"
                row.append(f"{lines} lines / {leak}")
        report_lines.append("| " + " | ".join(row) + " |")
        
    report_lines.extend([
        "",
        "---",
        "",
        "## 7. Individual ORM Detailed Breakdown",
        ""
    ])
    
    if not sorted_orms:
        report_lines.append("*(No individual runs recorded yet)*")
    else:
        for orm in sorted_orms:
            data = results[orm]
            report_lines.extend([
                f"### {orm.upper()} ({data.get('language', 'Unknown')})",
                f"- **Framework Version**: {data.get('version', 'N/A')}",
                f"- **Benchmark Timestamp**: {data.get('timestamp', 'N/A')}",
                f"- **Implementation Path**: `{data.get('path', 'N/A')}`",
                "",
                "#### Latency Distribution across Heavyweight Canonical Queries:",
                "| Query | Status | p50 (ms) | p95 (ms) | p99 (ms) | LoC | Throughput | Notes |",
                "| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |"
            ])
            for q_id, q_desc in HEAVY_QUERIES:
                q_data = data.get("canonical_queries", {}).get(q_id, {})
                report_lines.append(
                    f"| {q_id} ({q_desc}) | {q_data.get('status', '⏳')} | "
                    f"{format_num(q_data.get('p50_ms'))} | "
                    f"{format_num(q_data.get('p95_ms'))} | "
                    f"{format_num(q_data.get('p99_ms'))} | "
                    f"{q_data.get('loc', '-')} | "
                    f"{format_num(q_data.get('rows_per_sec'), precision=0)} | "
                    f"{q_data.get('notes', '-')} |"
                )
            report_lines.extend([
                "",
                "#### Deliberate Mistakes Diagnostics Summary:",
                "```text",
                data.get("deliberate_mistakes_log", "No diagnostic logs attached."),
                "```",
                "",
                "---",
                ""
            ])
            
    with open(REPORT_PATH, "w") as fp:
        fp.write("\n".join(report_lines) + "\n")
        
    print(f"Successfully generated master benchmark report: {REPORT_PATH}")

if __name__ == "__main__":
    generate_report()
