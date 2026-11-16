#!/usr/bin/env bash
set -e

BENCH_PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQLC_ROOT="$(cd "$BENCH_PKG_DIR/.." && pwd)"
REAL_PKG_DIR="$SQLC_ROOT/sqlc-postgres-air-bench"
MASTER_BENCH_DIR="$(cd "$SQLC_ROOT/../bench" && pwd)"

echo "=== Executing sqlc Benchmark Harness ==="

cd "$REAL_PKG_DIR"
export RESULTS_PATH="$MASTER_BENCH_DIR/results/sqlc.json"

docker run --rm --network bench_default \
    -v "$SQLC_ROOT:/app" \
    -v "$MASTER_BENCH_DIR/results:/results" \
    -e RESULTS_PATH="/results/sqlc.json" \
    -w /app/sqlc-postgres-air-bench \
    golang:alpine \
    go run .

if [ -f "$REAL_PKG_DIR/test/deliberate-mistakes/compile_mistake.sh" ]; then
    echo "=== Running Deliberate Mistakes Suite ==="
    python3 "$MASTER_BENCH_DIR/runner/test_mistakes.py" \
        --dir "$REAL_PKG_DIR/test/deliberate-mistakes" \
        --cmd "bash $REAL_PKG_DIR/test/deliberate-mistakes/compile_mistake.sh {file}" \
        --language "go"
fi

echo "=== Updating Master Report ==="
python3 "$MASTER_BENCH_DIR/runner/report_generator.py"
echo "=== sqlc Benchmark Completed ==="
