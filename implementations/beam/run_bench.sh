#!/usr/bin/env bash
set -e

BENCH_PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BEAM_ROOT="$(cd "$BENCH_PKG_DIR/.." && pwd)"
REAL_PKG_DIR="$BEAM_ROOT/beam-postgres-air-bench"
MASTER_BENCH_DIR="$(cd "$BEAM_ROOT/../bench" && pwd)"

echo "=== Executing Beam Benchmark Harness ==="

cd "$BEAM_ROOT"
cabal build exe:beam-air-bench
cabal run exe:beam-air-bench -- +RTS -N -T

echo "=== Running Deliberate Mistakes Suite ==="
python3 "$MASTER_BENCH_DIR/runner/test_mistakes.py" \
    --dir "$REAL_PKG_DIR/test/DeliberateMistakes" \
    --cmd "cabal exec -- ghc -fno-code -fno-diagnostics-show-caret -i$REAL_PKG_DIR/src {file}" \
    --language "haskell"

echo "=== Updating Master Report ==="
python3 "$MASTER_BENCH_DIR/runner/report_generator.py"
echo "=== Beam Benchmark Completed ==="
