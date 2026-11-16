#!/usr/bin/env bash
set -e

BENCH_PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ESQUELETO_ROOT="$(cd "$BENCH_PKG_DIR/.." && pwd)"
REAL_PKG_DIR="$ESQUELETO_ROOT/esqueleto-postgres-air-bench"
MASTER_BENCH_DIR="$(cd "$ESQUELETO_ROOT/../bench" && pwd)"

echo "=== Executing Esqueleto Benchmark Harness ==="

cd "$ESQUELETO_ROOT"
export RESULTS_PATH="$MASTER_BENCH_DIR/results/esqueleto.json"
cabal build exe:esqueleto-air-bench
cabal run exe:esqueleto-air-bench -- +RTS -N -T

if [ -f "$REAL_PKG_DIR/test/compile_mistake.sh" ]; then
    echo "=== Running Deliberate Mistakes Suite ==="
    python3 "$MASTER_BENCH_DIR/runner/test_mistakes.py" \
        --dir "$REAL_PKG_DIR/test/DeliberateMistakes" \
        --cmd "bash $REAL_PKG_DIR/test/compile_mistake.sh {file}" \
        --language "haskell"
fi

echo "=== Updating Master Report ==="
python3 "$MASTER_BENCH_DIR/runner/report_generator.py"
echo "=== Esqueleto Benchmark Completed ==="
