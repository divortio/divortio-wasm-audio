#!/bin/bash
#
# package-util.sh
#
# Assembles the separate ESM and UMD artifacts for @ffmpeg/util into a
# final 'dist' directory, then packages and validates it.
#

set -euo pipefail

# --- Helper Functions ---
validate_package() {
  local target_dir="$1"
  local critical_files=(
    "$target_dir/dist/esm/index.js"
    "$target_dir/dist/umd/index.js"
  )
  echo "  - Running validation for @ffmpeg/util..."
  for file_path in "${critical_files[@]}"; do
    if [ ! -s "$file_path" ]; then
      echo "❌ VALIDATION FAILED: Critical file is missing or empty: $file_path"
      echo "  - Contents of '$target_dir/dist':"
      ls -R "$target_dir/dist"
      exit 1
    else
      local file_size
      file_size=$(stat -c%s "$file_path")
      echo "  ✔️  OK: Found $file_path ($file_size bytes)."
    fi
  done
}

# --- Main Execution ---
echo "--- Packaging @ffmpeg/util ---"
ESM_ARTIFACT_DIR="dist/esm"
UMD_ARTIFACT_DIR="dist/umd"
SOURCE_PKG_DIR="packages/util"

echo "  - Assembling final 'dist' directory from ESM and UMD artifacts."
rm -rf "${SOURCE_PKG_DIR}/dist"
mkdir -p "${SOURCE_PKG_DIR}/dist/esm"
mkdir -p "${SOURCE_PKG_DIR}/dist/umd"
cp -r "${ESM_ARTIFACT_DIR}"/* "${SOURCE_PKG_DIR}/dist/esm/"
cp -r "${UMD_ARTIFACT_DIR}"/* "${SOURCE_PKG_DIR}/dist/umd/"

if [ ! -f "${SOURCE_PKG_DIR}/package.json" ]; then
    echo "❌ ERROR: Source package not found or is missing package.json at '${SOURCE_PKG_DIR}'"
    exit 1
fi
PKG_VERSION=$(jq -r .version "${SOURCE_PKG_DIR}/package.json")
VERSIONED_DIR="builds/util@${PKG_VERSION}"
LATEST_DIR="builds/util"

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
echo "✅ Successfully packaged and validated @ffmpeg/util@${PKG_VERSION}."