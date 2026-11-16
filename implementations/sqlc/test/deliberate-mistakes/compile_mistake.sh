#!/usr/bin/env bash
FILE="$1"
BN="$(basename "$FILE")"
docker run --rm -v /Users/tusharadhatrao/work/github_repo/orms/sqlc:/app -w /app/sqlc-postgres-air-bench golang:alpine go build -o /dev/null "/app/sqlc-postgres-air-bench/test/deliberate-mistakes/$BN"
