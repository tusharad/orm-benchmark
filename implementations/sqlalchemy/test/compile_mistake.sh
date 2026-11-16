#!/usr/bin/env bash
FILE="$1"
PYTHON_BIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.venv/bin" && pwd)/python"
if [ ! -f "$PYTHON_BIN" ]; then
    PYTHON_BIN="python3"
fi
"$PYTHON_BIN" "$FILE"
