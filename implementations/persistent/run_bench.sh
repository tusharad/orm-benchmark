#!/usr/bin/env bash
set -e

BENCH_PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PERSISTENT_ROOT="$(cd "$BENCH_PKG_DIR/.." && pwd)"
REAL_PKG_DIR="$PERSISTENT_ROOT/persistent-postgres-air-bench"
MASTER_BENCH_DIR="$(cd "$PERSISTENT_ROOT/../bench" && pwd)"

echo "=== Executing Persistent Benchmark Harness ==="

cd "$PERSISTENT_ROOT"
export RESULTS_PATH="$MASTER_BENCH_DIR/results/persistent.json"
cabal build exe:persistent-air-bench --allow-newer
cabal run exe:persistent-air-bench --allow-newer -- +RTS -N -T

if [ -f "$REAL_PKG_DIR/test/compile_mistake.sh" ]; then
    echo "=== Running Deliberate Mistakes Suite ==="
    python3 "$MASTER_BENCH_DIR/runner/test_mistakes.py" \
        --dir "$REAL_PKG_DIR/test/DeliberateMistakes" \
        --cmd "bash $REAL_PKG_DIR/test/compile_mistake.sh {file}" \
        --language "haskell"
fi

echo "=== Updating Master Report ==="
python3 "$MASTER_BENCH_DIR/runner/report_generator.py"
echo "=== Persistent Benchmark Completed ==="
