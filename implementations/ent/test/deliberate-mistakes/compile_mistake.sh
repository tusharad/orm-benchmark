#!/usr/bin/env bash
FILE="$1"
BN="$(basename "$FILE")"
docker run --rm -v /Users/tusharadhatrao/work/github_repo/orms/ent:/app -w /app/bench golang:alpine go build -o /dev/null "/app/bench/test/deliberate-mistakes/$BN"
