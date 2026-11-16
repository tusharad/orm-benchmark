#!/usr/bin/env bash
FILE="$1"
OPALEYE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$OPALEYE_ROOT" && cabal exec -- ghc -fno-code -fno-diagnostics-show-caret -Wno-type-equality-requires-operators -iopaleye-postgres-air-bench/src "$FILE"
