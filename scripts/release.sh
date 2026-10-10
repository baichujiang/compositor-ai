#!/bin/bash
# Build an ad hoc signed preview. This does not notarize or publish anything.
set -euo pipefail
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
release_work="${COMPOSITOR_AI_RELEASE_WORK:-$project_dir/build/ReleasePreview}"
dist_dir="${COMPOSITOR_AI_DIST:-$project_dir/dist}"
mkdir -p "$release_work" "$dist_dir"
xcodebuild build -project "$project_dir/Compositor.xcodeproj" -scheme Compositor \
  -destination 'platform=macOS,arch=arm64' -configuration Release -derivedDataPath "$release_work/DerivedData" \
  CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM=
built_app="$release_work/DerivedData/Build/Products/Release/Compositor AI.app"
version=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$built_app/Contents/Info.plist")
codesign --verify --deep --strict "$built_app"
package="$dist_dir/Compositor-AI-$version-macOS-arm64.zip"
if [[ -e "$package" ]]; then
  echo "Package already exists: $package. Remove it explicitly or choose another output directory." >&2
  exit 1
fi
ditto -c -k --sequesterRsrc --keepParent "$built_app" "$package"
(cd "$dist_dir" && shasum -a 256 "$(basename "$package")" > "$(basename "$package").sha256")
echo "Preview package: $package"
echo 'Ad hoc signed; not Apple notarized. See README for installation and release requirements.'
