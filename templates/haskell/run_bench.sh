#!/usr/bin/env bash
set -e

ORM_NAME="${1:-rel8}"
LANGUAGE="haskell"
BENCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "Running benchmark for $ORM_NAME..."

# 1. Build and run performance harness
if command -v stack >/dev/null 2>&1; then
    stack build
    stack exec bench-runner -- +RTS -N -T
elif command -v cabal >/dev/null 2>&1; then
    cabal build
    cabal run bench-runner -- +RTS -N -T
fi

# 2. Test Deliberate Mistakes (if test/DeliberateMistakes exists)
if [ -d "test/DeliberateMistakes" ]; then
    python3 "$BENCH_DIR/runner/test_mistakes.py" \
        --dir "test/DeliberateMistakes" \
        --cmd "ghc -fno-code -fno-diagnostics-show-caret {file}" \
        --language "haskell"
fi

# 3. Update master report
python3 "$BENCH_DIR/runner/report_generator.py"
echo "Benchmark completed and report updated."
