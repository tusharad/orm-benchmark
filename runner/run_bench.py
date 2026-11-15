#!/usr/bin/env python3
"""
Master Benchmark CLI Runner
Executes an ORM benchmark harness, aggregates performance & compiler metrics,
and updates the master BENCHMARK_REPORT.md.
"""

import argparse
import os
import subprocess
import sys
from pathlib import Path

BENCH_DIR = Path(__file__).resolve().parent.parent
ROOT_ORMS_DIR = BENCH_DIR.parent
RESULTS_DIR = BENCH_DIR / "results"

KNOWN_ORMS = [
    "beam", "dapper", "diesel", "drizzle-orm", "ecto",
    "efcore", "ent", "esqueleto", "gorm", "haskell-opaleye",
    "hasql", "hibernate-orm", "ihp", "jOOQ", "mikro-orm",
    "orville", "persistent", "prisma", "rails", "rel8",
    "sea-orm", "sqlalchemy", "sqlc", "squeal", "typeorm"
]

def check_postgres():
    """Ensures postgres-air container is accepting connections on localhost:5434."""
    import socket
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        s.settimeout(2.0)
        s.connect(("localhost", 5434))
        s.close()
        return True
    except Exception:
        return False

def run_orm_benchmark(orm_name: str):
    print(f"=== Starting Benchmark Suite for: {orm_name} ===")
    
    if not check_postgres():
        print("ERROR: Postgres Air database is not accessible on localhost:5434!", file=sys.stderr)
        print("Run `docker compose up -d` in the bench/ directory first.", file=sys.stderr)
        sys.exit(1)
        
    orm_dir = ROOT_ORMS_DIR / orm_name
    bench_harness_script = orm_dir / "bench" / "run_bench.sh"
    
    if not bench_harness_script.exists():
        # Fallback to check if run_bench.sh exists in orm root
        bench_harness_script = orm_dir / "run_bench.sh"
        
    if not bench_harness_script.exists():
        print(f"Notice: Benchmark harness script {bench_harness_script} does not exist yet.", file=sys.stderr)
        print(f"When ready, implement using the template in bench/templates/{orm_name} or generic.", file=sys.stderr)
        return False

    print(f"Executing: {bench_harness_script}")
    proc = subprocess.run(["bash", str(bench_harness_script)], cwd=orm_dir)
    if proc.returncode != 0:
        print(f"Warning: Benchmark harness for {orm_name} exited with status {proc.returncode}")
        return False

    print(f"=== Completed Benchmark Suite for: {orm_name} ===")
    # Refresh report
    generator = BENCH_DIR / "runner" / "report_generator.py"
    subprocess.run([sys.executable, str(generator)], check=True)
    return True

def main():
    parser = argparse.ArgumentParser(description="Postgres Air ORM Benchmark Runner")
    parser.add_argument("--orm", type=str, help="Name of the ORM to benchmark (e.g., rel8, beam, drizzle-orm)")
    parser.add_argument("--list", action="store_true", help="List all candidate ORMs")
    parser.add_argument("--report", action="store_true", help="Regenerate master BENCHMARK_REPORT.md")
    
    args = parser.parse_args()
    
    if args.list:
        print("Candidate ORMs in ~/work/github_repo/orms:")
        for orm in sorted(KNOWN_ORMS):
            print(f" - {orm}")
        return

    if args.report:
        generator = BENCH_DIR / "runner" / "report_generator.py"
        subprocess.run([sys.executable, str(generator)], check=True)
        return

    if args.orm:
        orm_norm = args.orm.lower().strip()
        run_orm_benchmark(orm_norm)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
