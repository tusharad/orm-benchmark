#!/usr/bin/env bash
set -e

BENCH_PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HASQL_ROOT="$(cd "$BENCH_PKG_DIR/.." && pwd)"
REAL_PKG_DIR="$HASQL_ROOT/hasql-postgres-air-bench"
MASTER_BENCH_DIR="$(cd "$HASQL_ROOT/../bench" && pwd)"

echo "=== Executing Hasql Benchmark Harness ==="

cd "$HASQL_ROOT"
export RESULTS_PATH="$MASTER_BENCH_DIR/results/hasql.json"
cabal build exe:hasql-air-bench --allow-newer
cabal run exe:hasql-air-bench --allow-newer -- +RTS -N -T

if [ -f "$REAL_PKG_DIR/test/compile_mistake.sh" ]; then
    echo "=== Running Deliberate Mistakes Suite ==="
    python3 "$MASTER_BENCH_DIR/runner/test_mistakes.py" \
        --dir "$REAL_PKG_DIR/test/DeliberateMistakes" \
        --cmd "bash $REAL_PKG_DIR/test/compile_mistake.sh {file}" \
        --language "haskell"
fi

echo "=== Updating Master Report ==="
python3 "$MASTER_BENCH_DIR/runner/report_generator.py"
echo "=== Hasql Benchmark Completed ==="
