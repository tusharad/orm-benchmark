#!/usr/bin/env bash
set -e

BENCH_PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ECTO_ROOT="$(cd "$BENCH_PKG_DIR/.." && pwd)"
REAL_PKG_DIR="$ECTO_ROOT/bench"
MASTER_BENCH_DIR="$(cd "$ECTO_ROOT/../bench" && pwd)"

echo "=== Executing Ecto Benchmark Harness ==="

cd "$REAL_PKG_DIR"
export RESULTS_PATH="$MASTER_BENCH_DIR/results/ecto.json"
mix run -e "EctoAirBench.Bench.run()"

echo "=== Running Deliberate Mistakes Suite ==="
python3 "$MASTER_BENCH_DIR/runner/test_mistakes.py" \
    --dir "$REAL_PKG_DIR/test/deliberate-mistakes" \
    --cmd "cd $REAL_PKG_DIR && mix run {file}" \
    --language "elixir"

echo "=== Updating Master Report ==="
python3 "$MASTER_BENCH_DIR/runner/report_generator.py"
echo "=== Ecto Benchmark Completed ==="
