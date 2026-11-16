#!/usr/bin/env bash
set -e

BENCH_PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEA_ORM_ROOT="$(cd "$BENCH_PKG_DIR/.." && pwd)"
REAL_PKG_DIR="$SEA_ORM_ROOT/sea-orm-postgres-air-bench"
MASTER_BENCH_DIR="$(cd "$SEA_ORM_ROOT/../bench" && pwd)"

echo "=== Executing SeaORM Benchmark Harness ==="

cd "$SEA_ORM_ROOT"
export RESULTS_PATH="$MASTER_BENCH_DIR/results/sea-orm.json"
cargo run --release -p sea-orm-postgres-air-bench

if [ -f "$REAL_PKG_DIR/test/compile_mistake.sh" ]; then
    echo "=== Running Deliberate Mistakes Suite ==="
    python3 "$MASTER_BENCH_DIR/runner/test_mistakes.py" \
        --dir "$REAL_PKG_DIR/test/DeliberateMistakes" \
        --cmd "bash $REAL_PKG_DIR/test/compile_mistake.sh {file}" \
        --language "rust"
fi

echo "=== Updating Master Report ==="
python3 "$MASTER_BENCH_DIR/runner/report_generator.py"
echo "=== SeaORM Benchmark Completed ==="
