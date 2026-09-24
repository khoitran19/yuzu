#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
scripts/build.sh
app=.build/dd/Build/Products/${CONFIGURATION:-Debug}/Yuzu.app
pkill -x Yuzu 2> /dev/null || true
if [[ -n "${YUZU_GITHUB_TOKEN:-}" ]]; then
  "$app/Contents/MacOS/Yuzu" "$@" &
else
  open "$app" --args "$@"
fi
