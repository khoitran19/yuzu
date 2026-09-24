#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
tuist generate --no-open > /dev/null
xcodebuild -workspace Yuzu.xcworkspace -scheme prfixture -configuration Release -derivedDataPath .build/dd \
  -destination "platform=macOS,arch=arm64" build \
  | xcbeautify --quiet
prfixture=.build/dd/Build/Products/Release/prfixture
"$prfixture" synth --files 50 --lines 1000 --seed 1 --out Fixtures/synthetic-50
"$prfixture" synth --files 300 --lines 20000 --seed 1 --out Fixtures/synthetic-300
"$prfixture" record https://github.com/isoapp/district/pull/6663 --out Fixtures/recorded/district-6663
