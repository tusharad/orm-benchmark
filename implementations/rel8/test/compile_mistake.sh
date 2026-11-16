#!/usr/bin/env bash
FILE="$1"
REL8_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REL8_ROOT" && cabal exec -- ghc -fno-code -fno-diagnostics-show-caret -Wno-type-equality-requires-operators -irel8-postgres-air-bench/src "$FILE"
