#!/usr/bin/env bash
# Usage: scripts/perf.sh <fixture-dir> [out.json] [app args…]
# Release build; scrolls the whole diff on the display link and prints frame pacing JSON.
set -euo pipefail
cd "$(dirname "$0")/.."
fixture=$1 out=${2:-.build/perf.json}
shift $(( $# >= 2 ? 2 : 1 ))
export CONFIGURATION=Release
[[ -n "${NO_BUILD:-}" ]] || scripts/build.sh
app=.build/dd/Build/Products/Release/PRViewer.app/Contents/MacOS/PRViewer
pkill -x PRViewer 2> /dev/null || true
perl -e 'alarm shift; exec @ARGV' "${TIMEOUT:-180}" "$app" -ApplePersistenceIgnoreState YES --fixture "$fixture" --perf-scroll "$PWD/$out" \
  --window-size "${SIZE:-1600x1000}" --appearance "${APPEARANCE:-dark}" "$@" > /dev/null 2>&1 || true
cat "$out"
