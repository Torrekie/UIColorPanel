#!/bin/bash
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
if [[ $# -ne 1 || "$1" != *.bundle ]]; then
  echo "Usage: $0 /path/to/new/UIColorPanelKit.bundle" >&2
  exit 2
fi
bundle_path="$1"
if [[ -e "$bundle_path" || -L "$bundle_path" ]]; then
  echo "Destination already exists: $bundle_path" >&2
  exit 2
fi

release_version="$(awk -F '[[:space:]]*=[[:space:]]*' '$1 == "MARKETING_VERSION" { print $2 }' "$repo_dir/Version.xcconfig")"
: "${release_version:?Missing MARKETING_VERSION in Version.xcconfig}"
mkdir -p "$(dirname "$bundle_path")"
trap 'rm -rf "$bundle_path"' EXIT
/usr/bin/ditto "$repo_dir/Resources/UIColorPanelKit.bundle" "$bundle_path"
/usr/bin/plutil -insert CFBundleShortVersionString -string "$release_version" "$bundle_path/Info.plist"
cp "$repo_dir/Sources/UIBuiltInPalettes.json" \
  "$repo_dir/Resources/PrivacyInfo.xcprivacy" "$bundle_path/"
mkdir "$bundle_path/Provenance"
cp "$repo_dir/Resources/SymbolOutlines.provenance.json" "$bundle_path/Provenance/"
cp "$repo_dir/reimpl/color_accessibility_api_manifest.json" "$bundle_path/Provenance/ColorAccessibility.json"
trap - EXIT
