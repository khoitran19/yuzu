#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
tuist generate --no-open > /dev/null
xcodebuild -workspace PRViewer.xcworkspace -scheme PRViewer-Workspace -derivedDataPath .build/dd -destination "platform=macOS,arch=arm64" test "$@" \
  | xcbeautify --quiet
