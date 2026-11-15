#!/usr/bin/env bash
set -e

ORM_NAME="${1:-drizzle-orm}"
BENCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "Running TypeScript benchmark for $ORM_NAME..."

npm install
npm run build
npm run bench

# Check deliberate mistakes if present
if [ -d "test/deliberate-mistakes" ]; then
    python3 "$BENCH_DIR/runner/test_mistakes.py" \
        --dir "test/deliberate-mistakes" \
        --cmd "npx tsc --noEmit {file}" \
        --language "typescript"
fi

python3 "$BENCH_DIR/runner/report_generator.py"
echo "Benchmark completed and report updated."
