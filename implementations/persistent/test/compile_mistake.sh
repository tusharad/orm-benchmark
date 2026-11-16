#!/usr/bin/env bash
FILE="$1"
PERSISTENT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PERSISTENT_ROOT" && cabal exec -- ghc -fno-code -fno-diagnostics-show-caret -Wno-type-equality-requires-operators -ipersistent-postgres-air-bench/src "$FILE"
