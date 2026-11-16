#!/usr/bin/env bash
set -e

BENCH_PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQLALCHEMY_ROOT="$(cd "$BENCH_PKG_DIR/.." && pwd)"
REAL_PKG_DIR="$SQLALCHEMY_ROOT/sqlalchemy-postgres-air-bench"
MASTER_BENCH_DIR="$(cd "$SQLALCHEMY_ROOT/../bench" && pwd)"
PYTHON_BIN="$SQLALCHEMY_ROOT/.venv/bin/python"

if [ ! -f "$PYTHON_BIN" ]; then
    PYTHON_BIN="python3"
fi

echo "=== Executing SQLAlchemy Benchmark Harness ==="

cd "$SQLALCHEMY_ROOT"
export RESULTS_PATH="$MASTER_BENCH_DIR/results/sqlalchemy.json"
"$PYTHON_BIN" "$REAL_PKG_DIR/src/main.py"

if [ -f "$REAL_PKG_DIR/test/compile_mistake.sh" ]; then
    echo "=== Running Deliberate Mistakes Suite ==="
    python3 "$MASTER_BENCH_DIR/runner/test_mistakes.py" \
        --dir "$REAL_PKG_DIR/test/DeliberateMistakes" \
        --cmd "bash $REAL_PKG_DIR/test/compile_mistake.sh {file}" \
        --language "python"
fi

echo "=== Updating Master Report ==="
python3 "$MASTER_BENCH_DIR/runner/report_generator.py"
echo "=== SQLAlchemy Benchmark Completed ==="
