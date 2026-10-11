#!/bin/bash
set -euo pipefail
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
derived_dir="${COMPOSITOR_AI_DERIVED_DATA:-$project_dir/build/DerivedData}"
xcodebuild build-for-testing -project "$project_dir/Compositor.xcodeproj" -scheme Compositor \
  -destination 'platform=macOS,arch=arm64' -configuration Debug -derivedDataPath "$derived_dir" CODE_SIGN_IDENTITY=-
xcodebuild test-without-building -project "$project_dir/Compositor.xcodeproj" -scheme Compositor \
  -destination 'platform=macOS,arch=arm64' -derivedDataPath "$derived_dir" -parallel-testing-enabled NO \
  -skip-testing:CompositorTests/FloatingPanelTests -skip-testing:CompositorTests/SliderSnapTests -skip-testing:CompositorTests/CameraRawSliderTests
xcodebuild test-without-building -project "$project_dir/Compositor.xcodeproj" -scheme Compositor \
  -destination 'platform=macOS,arch=arm64' -derivedDataPath "$derived_dir" -parallel-testing-enabled NO \
  -only-testing:CompositorTests/FloatingPanelTests -only-testing:CompositorTests/SliderSnapTests -only-testing:CompositorTests/CameraRawSliderTests
