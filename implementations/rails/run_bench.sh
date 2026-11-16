#!/usr/bin/env bash
set -e

BENCH_PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RAILS_ROOT="$(cd "$BENCH_PKG_DIR/.." && pwd)"
REAL_PKG_DIR="$RAILS_ROOT/bench"
MASTER_BENCH_DIR="$(cd "$RAILS_ROOT/../bench" && pwd)"
RUBY_BIN="/opt/homebrew/opt/ruby/bin/ruby"

echo "=== Executing Rails / ActiveRecord Benchmark Harness ==="

cd "$REAL_PKG_DIR"
$RUBY_BIN -I"$REAL_PKG_DIR/src" "$REAL_PKG_DIR/src/bench.rb"

echo "=== Running Deliberate Mistakes Suite ==="
python3 "$MASTER_BENCH_DIR/runner/test_mistakes.py" \
    --dir "$REAL_PKG_DIR/test/deliberate-mistakes" \
    --cmd "$RUBY_BIN {file}" \
    --language "ruby"

echo "=== Updating Master Report ==="
python3 "$MASTER_BENCH_DIR/runner/report_generator.py"
echo "=== Rails / ActiveRecord Benchmark Completed ==="
