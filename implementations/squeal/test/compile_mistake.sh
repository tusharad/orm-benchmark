#!/usr/bin/env bash
FILE="$1"
SQUEAL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$SQUEAL_ROOT" && cabal exec --allow-newer -- ghc -fno-code -fno-diagnostics-show-caret -Wno-unticked-promoted-constructors -isqueal-postgres-air-bench/src "$FILE"
