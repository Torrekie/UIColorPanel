#!/bin/bash
set -euo pipefail
repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
/usr/bin/xcrun xcodebuild -quiet -jobs 4 \
  -project "$repo_dir/UIColorPanelKit.xcodeproj" \
  -scheme UIColorPanelDemo -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$repo_dir/.build/DerivedData" \
  CODE_SIGNING_ALLOWED=NO "$@" build
