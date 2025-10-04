#!/bin/bash
#
# package-core-mt.sh
#
# This script is responsible for the final packaging and validation of the
# multi-threaded WASM core (@ffmpeg/core-mt). It is designed to be called by a
# dedicated job in the GitHub Actions workflow after the core has been compiled.
#
# The script assumes that the compiled package artifact (containing 'dist/',
# 'package.json', etc.) is available at the path 'packages/core-mt'.
#
# Workflow:
#   1. Reads the package version from 'packages/core-mt/package.json'.
#   2. Creates a versioned directory (e.g., 'builds/core-mt@0.12.10').
#   3. Copies the build artifacts into this versioned directory.
#   4. Runs validation to ensure the critical .wasm and .worker.js files are
#      present and not empty.
#   5. Creates a version-agnostic 'latest' directory (e.g., 'builds/core-mt').
#   6. Syncs the contents from the versioned directory to the 'latest' directory.
#   7. The final 'builds/' directory is then uploaded as an artifact for the
#      final 'commit' job.
#

# --- Script Configuration ---

# Exit immediately if a command exits with a non-zero status.
set -euo pipefail


# --- Helper Functions ---

#
# @typedef {string} FilePath - The full path to a file.
# @typedef {string} DirPath - The full path to a directory.
# @typedef {'core-mt'} PackageName - The name of the package being processed.
#

#
# Validates the contents of a newly packaged build directory.
#
# This function is critical for the multi-threaded core. It checks for the
# existence and non-zero size of BOTH the main WASM binary and the essential
# JavaScript worker file.
#
# @param {DirPath} target_dir - The path to the directory being validated (e.g., "builds/core-mt@0.12.10").
#
validate_package() {
  local target_dir="$1"
  # Define the list of critical files that MUST exist for a valid build.
  local critical_files=("ffmpeg-core.wasm" "ffmpeg-core.worker.js")

  echo "  - Running validation for @ffmpeg/core-mt..."

  # Loop through the list of critical files to perform checks.
  for file_name in "${critical_files[@]}"; do
    local found_path
    # The find command robustly locates the file anywhere within the 'dist' directory.
    found_path=$(find "$target_dir/dist" -name "$file_name" -type f -size +0c -print -quit)

    if [ -z "$found_path" ]; then
      echo "❌ VALIDATION FAILED: Critical file '$file_name' is missing or empty in '$target_dir/dist'."
      echo "  - Contents of '$target_dir/dist':"
      ls -R "$target_dir/dist"
      exit 1
    else
      local file_size
      file_size=$(stat -c%s "$found_path")
      echo "  ✔️  OK: Found $found_path ($file_size bytes)."
    fi
  done
}


# --- Main Execution ---

echo "--- Packaging @ffmpeg/core-mt ---"

# Define the source directory where the build artifact was placed.
SOURCE_PKG_DIR="packages/core-mt"

# Input Validation: Ensure the source directory and its package.json exist.
if [ ! -f "${SOURCE_PKG_DIR}/package.json" ]; then
    echo "❌ ERROR: Source package not found or is missing package.json at '${SOURCE_PKG_DIR}'"
    exit 1
fi

# Read the package version from the source package.json file.
PKG_VERSION=$(jq -r .version "${SOURCE_PKG_DIR}/package.json")
VERSIONED_DIR="builds/core-mt@${PKG_VERSION}"
LATEST_DIR="builds/core-mt"

# --- Phase 1: Create and Validate Versioned Build ---

echo "  - Creating versioned package at ${VERSIONED_DIR}"
mkdir -p "${VERSIONED_DIR}"
cp -r "${SOURCE_PKG_DIR}/dist" "${VERSIONED_DIR}/"

if [ -f "${SOURCE_PKG_DIR}/README.md" ]; then
  cp "${SOURCE_PKG_DIR}/README.md" "${VERSIONED_DIR}/"
fi

# Run validation on the newly created directory.
validate_package "${VERSIONED_DIR}"


# --- Phase 2: Create "Latest" Build ---

echo "  - Syncing 'latest' directory at ${LATEST_DIR}"
# Remove any old "latest" directory to ensure a clean sync.
rm -rf "${LATEST_DIR}"
# Copy the entire validated, versioned directory to the "latest" location.
cp -r "${VERSIONED_DIR}" "${LATEST_DIR}"


# --- Final Output ---

echo "" # Add a newline for cleaner log output.
echo "✅ Successfully packaged and validated @ffmpeg/core-mt@${PKG_VERSION}."