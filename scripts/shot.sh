#!/usr/bin/env bash
# Usage: scripts/shot.sh <fixture-dir> <out.png> [app args…]
# Loads a fixture, applies the app args, writes a window PNG, and quits.
set -euo pipefail
cd "$(dirname "$0")/.."
fixture=$1 out=$2
shift 2
[[ -n "${NO_BUILD:-}" ]] || scripts/build.sh
app=.build/dd/Build/Products/${CONFIGURATION:-Debug}/PRViewer.app/Contents/MacOS/PRViewer
pkill -x PRViewer 2> /dev/null || true
perl -e 'alarm shift; exec @ARGV' "${TIMEOUT:-90}" "$app" -ApplePersistenceIgnoreState YES --fixture "$fixture" --screenshot "$PWD/$out" \
  --window-size "${SIZE:-1600x1000}" --appearance "${APPEARANCE:-dark}" "$@" 2>&1 | grep '\[harness\]' || true
test -f "$out" && echo "wrote $out"
