#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
IHP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

export PKG_CONFIG_PATH="/opt/homebrew/opt/icu4c/lib/pkgconfig:$PKG_CONFIG_PATH"

echo "================================================================================"
echo "  IHP POSTGRES AIR BENCHMARK"
echo "================================================================================"

# 1. Build
echo "[Step 1/3] Building ihp-air-bench executable..."
cd "$IHP_DIR"
cabal build ihp-postgres-air-bench:exe:ihp-air-bench --allow-newer

# 2. Run Benchmark Harness
echo "[Step 2/3] Running Benchmark Harness..."
cabal exec ihp-air-bench -- +RTS -N -T -RTS

# Copy scorecard to bench/results/ihp.json
mkdir -p "$ROOT_DIR/bench/results"
if [ -f "$IHP_DIR/ihp_scorecard.json" ]; then
    cp "$IHP_DIR/ihp_scorecard.json" "$ROOT_DIR/bench/results/ihp.json"
fi

# 3. Deliberate Mistakes Verification
echo "[Step 3/3] Running Deliberate Mistakes Suite..."
python3 "$ROOT_DIR/bench/runner/test_mistakes.py" --dir "$SCRIPT_DIR/test/DeliberateMistakes" --cmd "bash $SCRIPT_DIR/test/compile_mistake.sh {file}" --language haskell

echo "================================================================================"
echo "  IHP BENCHMARK COMPLETED SUCCESSFULLY"
echo "================================================================================"
