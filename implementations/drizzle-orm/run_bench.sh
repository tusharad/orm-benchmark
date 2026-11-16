#!/usr/bin/env bash
set -e

BENCH_PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRIZZLE_ROOT="$(cd "$BENCH_PKG_DIR/.." && pwd)"
REAL_PKG_DIR="$DRIZZLE_ROOT/bench"
MASTER_BENCH_DIR="$(cd "$DRIZZLE_ROOT/../bench" && pwd)"

echo "=== Executing Drizzle ORM Benchmark Harness ==="

cd "$REAL_PKG_DIR"
npm run bench

echo "=== Running Deliberate Mistakes Suite ==="
python3 "$MASTER_BENCH_DIR/runner/test_mistakes.py" \
    --dir "$REAL_PKG_DIR/test/deliberate-mistakes" \
    --cmd "cd $REAL_PKG_DIR && npx tsc --noEmit --ignoreConfig --strict {file}" \
    --language "typescript"

echo "=== Updating Master Report ==="
python3 "$MASTER_BENCH_DIR/runner/report_generator.py"
echo "=== Drizzle ORM Benchmark Completed ==="
