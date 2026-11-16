#!/usr/bin/env bash
FILE="$1"
BN="$(basename "$FILE")"
BENCH_DIR="/Users/tusharadhatrao/work/github_repo/orms/jOOQ/bench"

docker run --rm \
  -v "$BENCH_DIR":/app \
  -w /app \
  eclipse-temurin:21-jdk-alpine \
  javac -cp /app/target/jooq-postgres-air-bench-1.0.0.jar "/app/test/deliberate-mistakes/$BN"
