#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
tuist generate --no-open > /dev/null
xcodebuild -workspace Yuzu.xcworkspace -scheme Yuzu -configuration "${CONFIGURATION:-Debug}" \
  -derivedDataPath .build/dd build | xcbeautify --quiet
