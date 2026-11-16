#!/usr/bin/env bash
FILE="$1"
PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_FILE="$PKG_DIR/src/bin/check_err.rs"

mkdir -p "$PKG_DIR/src/bin"
cp "$FILE" "$TEMP_FILE"

cd "$PKG_DIR/.."
cargo check -p diesel-postgres-air-bench --bin check_err 2>&1
STATUS=$?

rm -f "$TEMP_FILE"
exit $STATUS
