#!/usr/bin/env bash
FILE="$1"
IHP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export PKG_CONFIG_PATH="/opt/homebrew/opt/icu4c/lib/pkgconfig:$PKG_CONFIG_PATH"
cd "$IHP_ROOT" && cabal exec -- ghc -fno-code -fno-diagnostics-show-caret -Wno-type-equality-requires-operators -package ihp -package hasql -package ihp-postgres-air-bench "$FILE"
