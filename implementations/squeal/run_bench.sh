#!/usr/bin/env bash
set -e

BENCH_PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQUEAL_ROOT="$(cd "$BENCH_PKG_DIR/.." && pwd)"
REAL_PKG_DIR="$SQUEAL_ROOT/squeal-postgres-air-bench"
MASTER_BENCH_DIR="$(cd "$SQUEAL_ROOT/../bench" && pwd)"

echo "=== Executing Squeal-PostgreSQL Benchmark Harness ==="

cd "$SQUEAL_ROOT"
export RESULTS_PATH="$MASTER_BENCH_DIR/results/squeal.json"
cabal build exe:squeal-air-bench --allow-newer
cabal run exe:squeal-air-bench --allow-newer -- +RTS -N -T

if [ -f "$REAL_PKG_DIR/test/compile_mistake.sh" ]; then
    echo "=== Running Deliberate Mistakes Suite ==="
    python3 "$MASTER_BENCH_DIR/runner/test_mistakes.py" \
        --dir "$REAL_PKG_DIR/test/DeliberateMistakes" \
        --cmd "bash $REAL_PKG_DIR/test/compile_mistake.sh {file}" \
        --language "haskell"
fi

echo "=== Updating Master Report ==="
python3 "$MASTER_BENCH_DIR/runner/report_generator.py"
echo "=== Squeal Benchmark Completed ==="
