#!/usr/bin/env bash
set -e

BENCH_PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRISMA_ROOT="$(cd "$BENCH_PKG_DIR/.." && pwd)"
REAL_PKG_DIR="$PRISMA_ROOT/bench"
MASTER_BENCH_DIR="$(cd "$PRISMA_ROOT/../bench" && pwd)"

echo "=== Executing Prisma Benchmark Harness ==="

cd "$REAL_PKG_DIR"
npm run bench

echo "=== Running Deliberate Mistakes Suite ==="
python3 "$MASTER_BENCH_DIR/runner/test_mistakes.py" \
    --dir "$REAL_PKG_DIR/test/deliberate-mistakes" \
    --cmd "cd $REAL_PKG_DIR && npx tsc --noEmit --strict {file}" \
    --language "typescript"

echo "=== Updating Master Report ==="
python3 "$MASTER_BENCH_DIR/runner/report_generator.py"
echo "=== Prisma Benchmark Completed ==="
