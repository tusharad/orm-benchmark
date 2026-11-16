#!/usr/bin/env bash
set -e

BENCH_PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPALEYE_ROOT="$(cd "$BENCH_PKG_DIR/.." && pwd)"
REAL_PKG_DIR="$OPALEYE_ROOT/opaleye-postgres-air-bench"
MASTER_BENCH_DIR="$(cd "$OPALEYE_ROOT/../bench" && pwd)"

echo "=== Executing Opaleye Benchmark Harness ==="

cd "$OPALEYE_ROOT"
export RESULTS_PATH="$MASTER_BENCH_DIR/results/haskell-opaleye.json"
cabal build exe:opaleye-air-bench
cabal run exe:opaleye-air-bench -- +RTS -N -T

if [ -f "$REAL_PKG_DIR/test/compile_mistake.sh" ]; then
    echo "=== Running Deliberate Mistakes Suite ==="
    python3 "$MASTER_BENCH_DIR/runner/test_mistakes.py" \
        --dir "$REAL_PKG_DIR/test/DeliberateMistakes" \
        --cmd "bash $REAL_PKG_DIR/test/compile_mistake.sh {file}" \
        --language "haskell"
fi

echo "=== Updating Master Report ==="
python3 "$MASTER_BENCH_DIR/runner/report_generator.py"
echo "=== Opaleye Benchmark Completed ==="
