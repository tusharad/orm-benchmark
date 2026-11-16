#!/usr/bin/env bash
set -e

BENCH_PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REL8_ROOT="$(cd "$BENCH_PKG_DIR/.." && pwd)"
REAL_PKG_DIR="$REL8_ROOT/rel8-postgres-air-bench"
MASTER_BENCH_DIR="$(cd "$REL8_ROOT/../bench" && pwd)"

echo "=== Executing Rel8 Benchmark Harness ==="

cd "$REL8_ROOT"
export RESULTS_PATH="$MASTER_BENCH_DIR/results/rel8.json"
cabal build exe:rel8-air-bench
cabal run exe:rel8-air-bench -- +RTS -N -T

if [ -f "$REAL_PKG_DIR/test/compile_mistake.sh" ]; then
    echo "=== Running Deliberate Mistakes Suite ==="
    python3 "$MASTER_BENCH_DIR/runner/test_mistakes.py" \
        --dir "$REAL_PKG_DIR/test/DeliberateMistakes" \
        --cmd "bash $REAL_PKG_DIR/test/compile_mistake.sh {file}" \
        --language "haskell"
fi

echo "=== Updating Master Report ==="
python3 "$MASTER_BENCH_DIR/runner/report_generator.py"
echo "=== Rel8 Benchmark Completed ==="
