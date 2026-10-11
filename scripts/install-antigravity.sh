#!/bin/bash
# Install the official CLI version tested by this preview without changing shell profiles or existing CLIs.
set -euo pipefail
if [[ "$(uname -s)" != Darwin || "$(uname -m)" != arm64 ]]; then
  echo 'This installer requires an Apple Silicon Mac.' >&2
  exit 1
fi
cli_version=1.3.3
cli_url='https://storage.googleapis.com/antigravity-public/antigravity-cli/1.3.3-5524738307653632/darwin-arm/cli_mac_arm64.tar.gz'
cli_sha512='05ebb472149ca461e99f7870ce81fbdd48e3844f43b96a778c981d983421627c5bd02596dc8211ccd30b4cee0df8ca4d17b681f587ef22948ea4c703e9c7fcbd'
bin_dir="${COMPOSITOR_ANTIGRAVITY_BIN_DIR:-$HOME/.local/bin}"
cli_path="$bin_dir/agy"
if [[ -e "$cli_path" ]]; then
  existing_version=$(AGY_CLI_DISABLE_AUTO_UPDATE=1 "$cli_path" --version 2>/dev/null || true)
  if [[ "$existing_version" == "$cli_version" ]]; then
    echo "Antigravity CLI $cli_version is already installed: $cli_path"
    exit 0
  fi
  echo "Existing file was preserved: $cli_path" >&2
  echo 'Set COMPOSITOR_ANTIGRAVITY_BIN_DIR to another directory, then select that executable in AI Settings.' >&2
  exit 1
fi
staging_dir=$(mktemp -d "${TMPDIR:-/tmp}/compositor-antigravity.XXXXXX")
trap 'rm -rf "$staging_dir"' EXIT
archive="$staging_dir/cli.tar.gz"
curl -fsSL --retry 2 "$cli_url" -o "$archive"
actual_hash=$(shasum -a 512 "$archive" | awk '{print $1}')
if [[ "$actual_hash" != "$cli_sha512" ]]; then
  echo 'The official CLI archive did not match the expected SHA-512 checksum.' >&2
  exit 1
fi
tar -xzf "$archive" -C "$staging_dir" antigravity
mkdir -p "$bin_dir"
install -m 755 "$staging_dir/antigravity" "$cli_path"
echo "Installed official Antigravity CLI $cli_version: $cli_path"
echo "Run this path in Terminal to complete your own Google login: $cli_path"
