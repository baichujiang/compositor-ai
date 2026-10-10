#!/bin/bash
# Publish an already reviewed preview package to this fork, using GitHub CLI.
# Usage: ./scripts/publish.sh v0.1.0 path/to/release-notes.md
set -euo pipefail
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
repo=baichujiang/compositor-ai
tag="${1:?Provide the existing release tag}"
notes="${2:?Provide the release notes Markdown file}"
version="${tag#v}"
package="$project_dir/dist/Compositor-AI-$version-macOS-arm64.zip"
[[ -f "$package" && -f "$package.sha256" && -f "$notes" ]] || { echo 'Missing package, checksum or release notes.' >&2; exit 1; }
git -C "$project_dir" rev-parse --verify "refs/tags/$tag" >/dev/null
gh release create "$tag" "$package" "$package.sha256" --repo "$repo" --verify-tag --prerelease \
  --title "Compositor AI $version Preview" --notes-file "$notes"
