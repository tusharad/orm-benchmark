#!/usr/bin/env bash
set -e

BENCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MASTER_BENCH_DIR="$(cd "$BENCH_DIR/../../bench" && pwd)"

echo "=== Packaging Hibernate Benchmark Jar ==="
docker run --rm \
  -v "$BENCH_DIR":/app \
  -w /app \
  maven:3-eclipse-temurin-21-alpine \
  mvn package -DskipTests -q

echo "=== Running Hibernate Benchmark against Postgres Air ==="
docker run --rm \
  --network bench_default \
  -v "$BENCH_DIR":/app \
  -v "$MASTER_BENCH_DIR":/bench \
  -e RESULTS_PATH=/bench/results/hibernate-orm.json \
  -e DB_URL="jdbc:postgresql://postgres-air:5432/postgres_air?currentSchema=postgres_air,public" \
  -w /app \
  eclipse-temurin:21-jdk-alpine \
  java -Xms256m -Xmx2g -jar /app/target/hibernate-postgres-air-bench-1.0.0.jar

if [ -f "$BENCH_DIR/test/compile_mistake.sh" ]; then
    echo "=== Running Deliberate Mistakes Suite ==="
    python3 "$MASTER_BENCH_DIR/runner/test_mistakes.py" \
        --dir "$BENCH_DIR/test/deliberate-mistakes" \
        --cmd "bash $BENCH_DIR/test/compile_mistake.sh {file}" \
        --language "java"
fi

echo "=== Updating Master Report ==="
python3 "$MASTER_BENCH_DIR/runner/report_generator.py"

echo "=== Hibernate ORM Benchmark Completed Successfully ==="
