#!/bin/bash
#
# package-core.sh
#
# Packages and validates the single-threaded WASM core (@ffmpeg/core).
# It creates a versioned directory (e.g., 'builds/core@0.12.10') and a
# version-agnostic 'latest' directory ('builds/core').
#

set -euo pipefail

# --- Helper Functions ---
validate_package() {
  local target_dir="$1"
  local wasm_file_path
  echo "  - Running validation for @ffmpeg/core..."
  wasm_file_path=$(find "$target_dir/dist" -name "ffmpeg-core.wasm" -type f -size +0c -print -quit)
  if [ -z "$wasm_file_path" ]; then
    echo "❌ VALIDATION FAILED: Critical file 'ffmpeg-core.wasm' is missing or empty in '$target_dir/dist'."
    echo "  - Contents of '$target_dir/dist':"
    ls -R "$target_dir/dist"
    exit 1
  else
    local file_size
    file_size=$(stat -c%s "$wasm_file_path")
    echo "  ✔️  OK: Found $wasm_file_path ($file_size bytes)."
  fi
}

# --- Main Execution ---
echo "--- Packaging @ffmpeg/core ---"
SOURCE_PKG_DIR="packages/core"
if [ ! -f "${SOURCE_PKG_DIR}/package.json" ]; then
    echo "❌ ERROR: Source package not found or is missing package.json at '${SOURCE_PKG_DIR}'"
    exit 1
fi
PKG_VERSION=$(jq -r .version "${SOURCE_PKG_DIR}/package.json")
VERSIONED_DIR="builds/core@${PKG_VERSION}"
LATEST_DIR="builds/core"

echo "  - Creating versioned package at ${VERSIONED_DIR}"
mkdir -p "${VERSIONED_DIR}"
cp -r "${SOURCE_PKG_DIR}/dist" "${VERSIONED_DIR}/"
if [ -f "${SOURCE_PKG_DIR}/README.md" ]; then
  cp "${SOURCE_PKG_DIR}/README.md" "${VERSIONED_DIR}/"
fi
validate_package "${VERSIONED_DIR}"

echo "  - Syncing 'latest' directory at ${LATEST_DIR}"
rm -rf "${LATEST_DIR}"
cp -r "${VERSIONED_DIR}" "${LATEST_DIR}"

echo ""
echo "✅ Successfully packaged and validated @ffmpeg/core@${PKG_VERSION}."