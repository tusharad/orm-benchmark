#!/usr/bin/env bash
set -e

BENCH_PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DAPPER_ROOT="$(cd "$BENCH_PKG_DIR/.." && pwd)"
REAL_PKG_DIR="$DAPPER_ROOT/bench"
MASTER_BENCH_DIR="$(cd "$DAPPER_ROOT/../bench" && pwd)"

echo "=== Executing Dapper Benchmark Harness ==="

cd "$REAL_PKG_DIR"
export RESULTS_PATH="$MASTER_BENCH_DIR/results/Dapper.json"

docker run --rm --network bench_default \
    -v "$REAL_PKG_DIR:/app" \
    -v "$MASTER_BENCH_DIR/results:/results" \
    -e RESULTS_PATH="/results/Dapper.json" \
    -w /app \
    mcr.microsoft.com/dotnet/sdk:8.0-alpine \
    dotnet run -c Release

echo "=== Running Deliberate Mistakes Suite ==="
python3 "$MASTER_BENCH_DIR/runner/test_mistakes.py" \
    --dir "$REAL_PKG_DIR/test/deliberate-mistakes" \
    --cmd "bash $REAL_PKG_DIR/test/deliberate-mistakes/compile_mistake.sh {file}" \
    --language "csharp"

echo "=== Updating Master Report ==="
python3 "$MASTER_BENCH_DIR/runner/report_generator.py"
echo "=== Dapper Benchmark Completed ==="
