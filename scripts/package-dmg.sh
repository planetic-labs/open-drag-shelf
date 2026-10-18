#!/bin/bash
set -euo pipefail

# Builds a public ARM64 preview using ad-hoc signing, without Apple credentials.
version=${1:-0.0.0}
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo 'Version must have the form 0.1.0.' >&2
  exit 1
fi
cd "$(dirname "$0")/.."
output_dir="$PWD/build/distribution"
derived_dir="$PWD/build/DerivedData"
staging_dir=$(mktemp -d "${TMPDIR:-/tmp}/plupo-dmg.XXXXXX")
trap 'rm -rf "$staging_dir"' EXIT
mkdir -p "$output_dir"

xcodebuild -project Plupo.xcodeproj -scheme Plupo \
  -configuration Release -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath "$derived_dir" \
  ARCHS=arm64 ONLY_ACTIVE_ARCH=YES \
  CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM= \
  CODE_SIGNING_ALLOWED=YES CODE_SIGNING_REQUIRED=YES \
  CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
  MARKETING_VERSION="$version" CURRENT_PROJECT_VERSION=1 \
  DEBUG_INFORMATION_FORMAT=dwarf SWIFT_SERIALIZE_DEBUGGING_OPTIONS=NO \
  build

app="$derived_dir/Build/Products/Release/Plupo.app"
codesign --verify --deep --strict "$app"
architectures=$(lipo -archs "$app/Contents/MacOS/Plupo")
if [[ "$architectures" != arm64 ]]; then
  echo "Unexpected architectures: $architectures" >&2
  exit 1
fi
# Shipping only the app avoids Xcode logs, debug symbols and local configuration.
ditto "$app" "$staging_dir/Plupo.app"
ln -s /Applications "$staging_dir/Applications"
cp LICENSE "$staging_dir/LICENSE.txt"
cat > "$staging_dir/Read Me.txt" <<'NOTES'
Plupo — Drag. Drop. Keep moving.

Requires macOS 15.7 or later and an Apple Silicon Mac (M1 or newer).
Drag Plupo into Applications, eject this disk image, then open Plupo.

This early preview has an ad-hoc signature, not an Apple Developer ID
signature, and has not been notarized by Apple. macOS may block first launch.
If you trust this download, try opening it once, then go to System Settings
> Privacy & Security > Open Anyway and confirm.
Do not disable Gatekeeper or other system-wide security protections.

Plupo is in early development. Features and behavior may change.
Source, known limitations and issue reports:
https://github.com/planetic-labs/open-drag-shelf

Released under the MIT License; see LICENSE.txt.
NOTES

hdiutil create -volname Plupo -srcfolder "$staging_dir" \
  -format UDZO -ov "$output_dir/Plupo-arm64.dmg"
hdiutil verify "$output_dir/Plupo-arm64.dmg"
(cd "$output_dir" && shasum -a 256 Plupo-arm64.dmg > SHA256SUMS.txt)
echo "Created $output_dir/Plupo-arm64.dmg"
