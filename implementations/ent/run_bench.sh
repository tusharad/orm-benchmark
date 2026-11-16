#!/usr/bin/env bash
set -e

BENCH_PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENT_ROOT="$(cd "$BENCH_PKG_DIR/.." && pwd)"
REAL_PKG_DIR="$ENT_ROOT/bench"
MASTER_BENCH_DIR="$(cd "$ENT_ROOT/../bench" && pwd)"

echo "=== Executing ent Benchmark Harness ==="

cd "$REAL_PKG_DIR"
export RESULTS_PATH="$MASTER_BENCH_DIR/results/ent.json"

docker run --rm --network bench_default \
    -v "$ENT_ROOT:/app" \
    -v "$MASTER_BENCH_DIR/results:/results" \
    -e RESULTS_PATH="/results/ent.json" \
    -w /app/bench \
    golang:alpine \
    go run .

echo "=== Running Deliberate Mistakes Suite ==="
python3 "$MASTER_BENCH_DIR/runner/test_mistakes.py" \
    --dir "$REAL_PKG_DIR/test/deliberate-mistakes" \
    --cmd "bash $REAL_PKG_DIR/test/deliberate-mistakes/compile_mistake.sh {file}" \
    --language "go"

echo "=== Updating Master Report ==="
python3 "$MASTER_BENCH_DIR/runner/report_generator.py"
echo "=== ent Benchmark Completed ==="
