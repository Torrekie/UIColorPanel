#!/bin/bash
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd -P)"
variant=public
platform=all
pencils=${UICOLORPANEL_ENABLE_PENCILS:-1}
output_path=
while [[ $# -gt 0 ]]; do
  case "$1" in
    --variant|--platform|--output|--pencils)
      if [[ $# -lt 2 ]]; then echo "Missing value for $1" >&2; exit 2; fi
      case "$1" in
        --variant) variant="$2" ;;
        --platform) platform="$2" ;;
        --output) output_path="$2" ;;
        --pencils) pencils="$2" ;;
      esac
      shift 2
      ;;
    --help)
      echo "Usage: $0 [--variant public|spi] [--pencils 0|1] [--platform all|device|simulator] [--output new-directory]"
      exit 0
      ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done
case "$pencils" in 0|1) ;; *) echo "--pencils expects 0 or 1" >&2; exit 2 ;; esac
case "$variant" in
  public) private_api=0; product_name=UIColorPanelKitPublic ;;
  spi) private_api=1; product_name=UIColorPanelKitSPI ;;
  *) echo "Unknown variant: $variant" >&2; exit 2 ;;
esac
case "$platform" in
  all) sdks=(iphoneos iphonesimulator) ;;
  device) sdks=(iphoneos) ;;
  simulator) sdks=(iphonesimulator) ;;
  *) echo "Unknown platform: $platform" >&2; exit 2 ;;
esac
output_path="${output_path:-$repo_dir/.build/releases/$product_name}"
if [[ -e "$output_path" || -L "$output_path" ]]; then
  echo "Destination already exists: $output_path" >&2
  exit 2
fi
mkdir -p "$(dirname "$output_path")"
staging_path="$(mktemp -d "$(dirname "$output_path")/.uicolorpanel-release.XXXXXX")"
trap 'rm -rf "$staging_path"' EXIT

source_revision=unknown
if [[ "$(git -C "$repo_dir" rev-parse --show-toplevel 2>/dev/null)" == "$repo_dir" ]]; then
  source_revision="$(git -C "$repo_dir" rev-parse --verify HEAD 2>/dev/null || echo unknown)"
fi

# DWARF and the device bitcode command line both embed the build machine's paths.
for sdk in "${sdks[@]}"; do
  if [[ "$sdk" == iphoneos ]]; then destination='generic/platform=iOS'; else destination='generic/platform=iOS Simulator'; fi
  /usr/bin/xcrun xcodebuild -quiet -jobs 4 \
    -project "$repo_dir/UIColorPanelKit.xcodeproj" -scheme UIColorPanelKit \
    -configuration Release -sdk "$sdk" -destination "$destination" \
    -derivedDataPath "$repo_dir/.build/DerivedData" \
    CODE_SIGNING_ALLOWED=NO ONLY_ACTIVE_ARCH=NO GCC_GENERATE_DEBUGGING_SYMBOLS=NO ENABLE_BITCODE=NO \
    UICOLORPANEL_ENABLE_PRIVATE_API="$private_api" UICOLORPANEL_ENABLE_PENCILS="$pencils" build
  products_path="$repo_dir/.build/DerivedData/Build/Products/Release-$sdk"
  mkdir "$staging_path/$sdk"
  cp "$products_path/libUIColorPanelKit.a" "$staging_path/$sdk/lib$product_name.a"
done

# Copy the current Public phase rather than a cache that may retain older headers.
/usr/bin/python3 - "$repo_dir" "$staging_path/include/UIColorPanelKit" "$pencils" <<'PY'
import json
from pathlib import Path
import shutil
import subprocess
import sys

repo_path, header_path = map(Path, sys.argv[1:3])
pencils_enabled = sys.argv[3] == "1"
project = json.loads(subprocess.check_output([
    "/usr/bin/plutil", "-convert", "json", "-o", "-",
    str(repo_path / "UIColorPanelKit.xcodeproj/project.pbxproj"),
]))["objects"]
header_path.mkdir(parents=True)
for build_id in project["4C86DB6A8DEEA0325393CD57"]["files"]:
    entry = project[build_id]
    if "Public" not in entry.get("settings", {}).get("ATTRIBUTES", []):
        continue
    source = repo_path / project[entry["fileRef"]]["path"]
    if not pencils_enabled:
        if source.name in {"UIColoredPencil.h", "UIColorPickerPencilView.h", "UIColorPickerPencils.h"}:
            continue
        if source.name == "UIColorPanelTypes.h":
            content = source.read_text()
            default = "#define UICOLORPANEL_ENABLE_PENCILS 1"
            if default not in content:
                raise SystemExit("Missing default pencil setting in UIColorPanelTypes.h")
            (header_path / source.name).write_text(content.replace(default, "#define UICOLORPANEL_ENABLE_PENCILS 0"))
            continue
    shutil.copyfile(source, header_path / source.name)
PY

cat > "$staging_path/include/UIColorPanelKit/module.modulemap" <<'EOF'
module UIColorPanelKit {
  umbrella header "UIColorPanelKit.h"
  export *
  module * { export * }
}
EOF
"$repo_dir/tools/package-resources.sh" "$staging_path/UIColorPanelKit.bundle"
release_version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$staging_path/UIColorPanelKit.bundle/Info.plist")"
cp "$repo_dir/LICENSE" "$staging_path/"
cp "$repo_dir/Resources/PrivacyInfo.xcprivacy" "$staging_path/PrivacyInfo.xcprivacy"
cat > "$staging_path/UIColorPanelKit.xcconfig" <<EOF
// Define UICOLORPANELKIT_ROOT in the host to this distribution directory.
UICOLORPANEL_ENABLE_PRIVATE_API = $private_api
UICOLORPANEL_ENABLE_PENCILS = $pencils
GCC_PREPROCESSOR_DEFINITIONS = \$(inherited) UICOLORPANEL_ENABLE_PRIVATE_API=\$(UICOLORPANEL_ENABLE_PRIVATE_API) UICOLORPANEL_ENABLE_PENCILS=\$(UICOLORPANEL_ENABLE_PENCILS)
HEADER_SEARCH_PATHS = \$(inherited) "\$(UICOLORPANELKIT_ROOT)/include"
LIBRARY_SEARCH_PATHS[sdk=iphoneos*] = \$(inherited) "\$(UICOLORPANELKIT_ROOT)/iphoneos"
LIBRARY_SEARCH_PATHS[sdk=iphonesimulator*] = \$(inherited) "\$(UICOLORPANELKIT_ROOT)/iphonesimulator"
OTHER_LDFLAGS = \$(inherited) -ObjC -l$product_name -framework UIKit -framework Foundation -framework CoreGraphics -framework QuartzCore -framework CoreImage -framework ImageIO
EOF
cat > "$staging_path/BUILD_VARIANT.txt" <<EOF
$product_name
Version: $release_version
UICOLORPANEL_ENABLE_PRIVATE_API=$private_api
UICOLORPANEL_ENABLE_PENCILS=$pencils
iOS deployment target: 12.0
Platforms: ${sdks[*]}
Source revision: $source_revision
Working-tree edits, if any, are included; this revision is not a clean-tree certification.
Project code: BSD-2-Clause (LICENSE). Apple-origin localization data retains its original rights.
EOF
cat > "$staging_path/INTEGRATE.md" <<EOF
# $product_name $release_version

This is an Objective-C/UIKit static library for iOS 12+. It has no remote dependencies.
Use the iphoneos library on devices and iphonesimulator library in Simulator; do not
combine these two platform archives with lipo. Never link both public and SPI variants.

1. Define UICOLORPANELKIT_ROOT to this directory in your app's xcconfig, then include
   UIColorPanelKit.xcconfig. It selects this variant's headers, library, frameworks,
   -ObjC flag and UICOLORPANEL_ENABLE_PRIVATE_API=$private_api.
2. Add UIColorPanelKit.bundle as one folder resource in the app's Copy Bundle Resources.
3. Add PrivacyInfo.xcprivacy at the app bundle root. If the app already has a privacy
   manifest, merge this file's UserDefaults reasons into that file instead of adding
   a second root file. The .a itself cannot carry a privacy manifest.
4. Import <UIColorPanelKit/UIColorPanelKit.h> in your iOS app. Use UIKit APIs on
   the main thread. When compiling the repository sources directly, add Sources/
   and Sources/RecoveredElements/ to the header search paths and use
   #import "UIColorPanelKit.h" instead.

This package uses UICOLORPANEL_ENABLE_PENCILS=$pencils. With pencils disabled,
the fifth toolbar item opens Grid directly. The pencil palette draws and tints its
artwork at runtime. Spectrum and the Well ring are also drawn at runtime.
App-local favorites use standard defaults. To share the data across processes,
select the same App Group and key in each entitled host. Host the full panel in an
iOS app target. Its window management uses UIApplication.sharedApplication, which
is unavailable to app extensions. Private builds with use_spi=YES can also use the
system picker file on iOS 14+ if the host already has filesystem access. The public
build uses public APIs.
Project code is licensed under BSD-2-Clause. Apple-origin resources retain their
original rights. See LICENSE and UIColorPanelKit.bundle/Provenance.
EOF
mv "$staging_path" "$output_path"
trap - EXIT
echo "Created $output_path"
