#!/usr/bin/env python3
"""
Metrics Collector for Postgres Air ORM Benchmarks
Provides utilities for measuring:
- Heavyweight canonical queries (HQ01 through HQ16)
- Deserialization and hydration throughput (rows/sec, MB/sec)
- Application-level concurrency scalability (C = 1, 10, 50, 100) and tail latencies
- Lines of Code (LoC) and Tokens
- Unique non-standard operators
- Compiler diagnostic line counts and type leakage (The Deliberate Mistake Suite)
- Memory allocation, Max RSS, and GC pause metrics
- Generates standard results/<orm>.json and triggers report updates
"""

import json
import os
import re
import resource
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

BENCH_DIR = Path(__file__).resolve().parent.parent
RESULTS_DIR = BENCH_DIR / "results"

HEAVY_QUERY_IDS = [f"HQ{i:02d}" for i in range(1, 17)]

class MetricsCollector:
    def __init__(self, orm_name: str, language: str, version: str = "Unknown", path: str = ""):
        self.orm_name = orm_name
        self.language = language
        self.version = version
        self.path = path
        self.data = {
            "orm": orm_name,
            "language": language,
            "version": version,
            "path": path,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "summary": {},
            "canonical_queries": {},
            "hydration_benchmarks": {},
            "concurrency_benchmarks": {},
            "ergonomics": {},
            "deliberate_mistakes": {},
            "performance": {},
            "deliberate_mistakes_log": ""
        }

    def record_heavy_query(
        self,
        q_id: str,
        status: str,
        p50_ms: float = None,
        p95_ms: float = None,
        p99_ms: float = None,
        loc: int = None,
        rows_per_sec: float = None,
        notes: str = ""
    ):
        """Records metrics for one of HQ01 through HQ16."""
        self.data["canonical_queries"][q_id] = {
            "status": status,
            "p50_ms": p50_ms,
            "p95_ms": p95_ms,
            "p99_ms": p99_ms,
            "loc": loc,
            "rows_per_sec": rows_per_sec,
            "notes": notes
        }

    def record_hydration(
        self,
        test_id: str,
        total_rows: int,
        total_fields: int,
        duration_ms: float,
        rows_per_sec: float,
        mb_per_sec: float,
        heap_allocated_mb: float
    ):
        """Records massive hydration and deserialization throughput."""
        self.data["hydration_benchmarks"][test_id] = {
            "total_rows": total_rows,
            "total_fields": total_fields,
            "duration_ms": duration_ms,
            "rows_per_sec": rows_per_sec,
            "mb_per_sec": mb_per_sec,
            "heap_allocated_mb": heap_allocated_mb
        }

    def record_concurrency(
        self,
        concurrency_level: int,
        rps: float,
        p50_ms: float,
        p90_ms: float,
        p95_ms: float,
        p99_ms: float,
        p999_ms: float,
        error_count: int = 0
    ):
        """Records throughput and latency percentiles under load."""
        self.data["concurrency_benchmarks"][f"C{concurrency_level}"] = {
            "concurrency": concurrency_level,
            "rps": rps,
            "p50_ms": p50_ms,
            "p90_ms": p90_ms,
            "p95_ms": p95_ms,
            "p99_ms": p99_ms,
            "p999_ms": p999_ms,
            "error_count": error_count
        }

    def record_deliberate_mistake(
        self,
        e_id: str,
        line_count: int,
        zero_leakage: bool,
        raw_output: str = ""
    ):
        """Records compiler error UX metrics for E01 through E10."""
        self.data["deliberate_mistakes"][e_id] = {
            "line_count": line_count,
            "zero_leakage": zero_leakage,
            "raw_output": raw_output
        }
        if raw_output:
            self.data["deliberate_mistakes_log"] += f"\n--- {e_id} Diagnostics ---\n{raw_output}\n"

    def record_ergonomics(
        self,
        loc: int,
        tokens: int,
        unique_operators: int,
        operator_score: float,
        blast_radius_lines: int,
        blast_radius_files: int
    ):
        """Records readability and schema change blast radius."""
        self.data["ergonomics"] = {
            "loc": loc,
            "tokens": tokens,
            "unique_operators": unique_operators,
            "operator_score": operator_score,
            "blast_radius_lines": blast_radius_lines,
            "blast_radius_files": blast_radius_files
        }

    def record_performance(
        self,
        peak_rps: float,
        total_allocated_mb: float,
        max_heap_mb: float,
        gc_minor_collections: int = 0,
        gc_major_collections: int = 0,
        gc_pause_total_ms: float = 0.0
    ):
        """Records system-level performance, memory, and GC metrics."""
        self.data["performance"] = {
            "peak_rps": peak_rps,
            "total_allocated_mb": total_allocated_mb,
            "max_heap_mb": max_heap_mb,
            "gc_minor_collections": gc_minor_collections,
            "gc_major_collections": gc_major_collections,
            "gc_pause_total_ms": gc_pause_total_ms
        }

    def compute_summary(self):
        """Calculates aggregate score and averages for the executive leaderboard."""
        p95_list = [
            v["p95_ms"] for v in self.data["canonical_queries"].values()
            if v.get("p95_ms") is not None
        ]
        avg_p95 = sum(p95_list) / len(p95_list) if p95_list else None
        
        passed_queries = sum(
            1 for v in self.data["canonical_queries"].values()
            if v.get("status") in ["✅", "PASS"]
        )
        
        mistake_score = sum(
            1 for v in self.data["deliberate_mistakes"].values()
            if v.get("zero_leakage") is True
        )
        
        # Hydration speed
        hq01_rate = self.data.get("hydration_benchmarks", {}).get("HQ01", {}).get("rows_per_sec", 0)
        
        # Overall score formula out of 100:
        # 35% Heavy query completeness (16 queries)
        # 25% Latency & execution throughput
        # 15% Deserialization & memory efficiency
        # 15% Compiler UX (The Deliberate Mistakes)
        # 10% Ergonomics & Operator conciseness
        score = (passed_queries / 16.0) * 35.0 + (mistake_score / 10.0) * 15.0
        
        if avg_p95:
            latency_score = max(0.0, 25.0 - (avg_p95 / 20.0))
            score += latency_score
            
        if hq01_rate > 0:
            hydration_score = min(15.0, (hq01_rate / 50000.0) * 15.0)
            score += hydration_score
            
        if self.data["ergonomics"].get("unique_operators") is not None:
            op_penalty = max(0.0, 10.0 - (self.data["ergonomics"]["unique_operators"] * 1.5))
            score += op_penalty
            
        self.data["summary"] = {
            "overall_score": round(score, 1),
            "passed_queries": passed_queries,
            "total_queries": 16,
            "avg_p95_ms": round(avg_p95, 2) if avg_p95 else None,
            "peak_rps": self.data["performance"].get("peak_rps"),
            "hydration_rows_sec": round(hq01_rate, 0) if hq01_rate else None,
            "max_heap_mb": self.data["performance"].get("max_heap_mb"),
            "blast_radius_lines": self.data["ergonomics"].get("blast_radius_lines"),
            "mistake_score": mistake_score
        }

    def save(self):
        self.compute_summary()
        RESULTS_DIR.mkdir(parents=True, exist_ok=True)
        out_file = RESULTS_DIR / f"{self.orm_name}.json"
        with open(out_file, "w") as fp:
            json.dump(self.data, fp, indent=2)
        print(f"Metrics saved to {out_file}")

        # Automatically trigger report regeneration
        report_script = BENCH_DIR / "runner" / "report_generator.py"
        if report_script.exists():
            subprocess.run([sys.executable, str(report_script)], check=False)
