#!/usr/bin/env bash
FILE="$1"
ORVILLE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ORVILLE_ROOT" && cabal exec -- ghc -fno-code -fno-diagnostics-show-caret -Wno-type-equality-requires-operators -iorville-postgres-air-bench/src "$FILE"
