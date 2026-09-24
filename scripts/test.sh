#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
tuist generate --no-open > /dev/null
xcodebuild -workspace Yuzu.xcworkspace -scheme Yuzu-Workspace -derivedDataPath .build/dd -destination "platform=macOS,arch=arm64" test "$@" \
  | xcbeautify --quiet
