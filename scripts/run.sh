#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
scripts/build.sh
app=.build/dd/Build/Products/${CONFIGURATION:-Debug}/PRViewer.app
pkill -x PRViewer 2> /dev/null || true
if [[ -n "${PRVIEWER_GITHUB_TOKEN:-}" ]]; then
  "$app/Contents/MacOS/PRViewer" "$@" &
else
  open "$app" --args "$@"
fi
