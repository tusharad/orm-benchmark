#!/usr/bin/env bash
FILE="$1"
HASQL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$HASQL_ROOT" && cabal exec -- ghc -fno-code -fno-diagnostics-show-caret -Wno-type-equality-requires-operators -ihasql-postgres-air-bench/src "$FILE"
