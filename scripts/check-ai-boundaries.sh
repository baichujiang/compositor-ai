#!/bin/bash
set -euo pipefail
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
python3 "$project_dir/scripts/check-ai-boundaries.py"
# Compile the real service, providers, contract, and panel without any editor/renderer/model source.
# The only shared source is the Foundation-only display localization helper.
xcrun swiftc -typecheck -swift-version 5 -default-isolation MainActor \
  -enable-upcoming-feature NonisolatedNonsendingByDefault \
  -module-name CompositorAIIsolation \
  "$project_dir/Compositor/Localization/AppLocalization.swift" \
  "$project_dir/Compositor/AI/Core/"*.swift "$project_dir/Compositor/AI/UI/"*.swift
echo 'AI core and panel compile without native editor sources.'
