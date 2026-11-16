#!/usr/bin/env bash
FILE="$1"
ESQUELETO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ESQUELETO_ROOT" && cabal exec -- ghc -fno-code -fno-diagnostics-show-caret -Wno-type-equality-requires-operators -iesqueleto-postgres-air-bench/src "$FILE"
