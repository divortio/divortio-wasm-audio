#!/bin/bash
#
# organize_builds.sh
#
# This script is responsible for organizing the raw build artifacts from the
# 'packages/' directory into a clean, developer-friendly structure within the
# 'builds/' directory. It is designed to be run within the GitHub Actions
# environment after all build steps are complete.
#
# The script performs four main functions for each package:
#   1. Packaging: It creates a versioned directory (e.g., 'core@0.12.10')
#      and copies the essential build artifacts ('dist/', 'README.md', and
#      the build receipt) into it.
#   2. Validation: It performs critical checks to ensure that the core
#      build artifacts (like .wasm files) exist and are not empty. If
#      validation fails, the script will exit with an error.
#   3. "Latest" Sync: It creates a version-agnostic directory (e.g., 'core')
#      that mirrors the content of the most recently built versioned
#      directory, providing a stable path for developers.
#   4. History Preservation: It is careful not to delete the top-level
#      'builds' directory, allowing a history of versioned builds to be
#      accumulated in the repository over time.
#

# --- Script Configuration ---

# Exit immediately if a command exits with a non-zero status.
set -euo pipefail


# --- Helper Functions ---

#
# Validates the contents of a newly packaged build directory.
#
# @param $1: The path to the newly created versioned directory (e.g., "builds/core@0.12.10").
# @param $2: The name of the package (e.g., "core").
#
validate_package() {
  local target_dir="$1"
  local pkg_name="$2"
  local files_to_check=()

  echo "  - Running validation for $pkg_name..."

  case "$pkg_name" in
    core)
      files_to_check+=("$target_dir/dist/esm/ffmpeg-core.wasm")
      ;;
    core-mt)
      files_to_check+=("$target_dir/dist/esm/ffmpeg-core.wasm")
      files_to_check+=("$target_dir/dist/esm/ffmpeg-core.worker.js")
      ;;
    ffmpeg|util)
      files_to_check+=("$target_dir/dist/esm/index.js")
      ;;
  esac

  for file_path in "${files_to_check[@]}"; do
    if [ ! -s "$file_path" ]; then
      echo "❌ VALIDATION FAILED: Critical file is missing or empty: $file_path"
      exit 1
    else
      local file_size=$(stat -c%s "$file_path")
      echo "  ✔️  OK: Found $file_path ($file_size bytes)."
    fi
  done
}

#
# Organizes a single package into its versioned directory.
#
# @param $1: The path to the source package directory (e.g., "packages/core").
#
organize_package() {
  local pkg_path="$1"
  local pkg_name=$(basename "$pkg_path")
  local pkg_version=$(jq -r .version "$pkg_path/package.json")
  local target_dir="builds/$pkg_name@$pkg_version"

  echo "Packaging $pkg_name@$pkg_version..."

  mkdir -p "$target_dir"
  cp -r "$pkg_path/dist" "$target_dir/"

  if [ -f "$pkg_path/README.md" ]; then
    cp "$pkg_path/README.md" "$target_dir/"
  fi

  if [[ "$pkg_name" == "core" || "$pkg_name" == "core-mt" ]]; then
    cp build-receipt.json "$target_dir/"
  fi

  validate_package "$target_dir" "$pkg_name"
}

#
# Creates a version-agnostic "latest" directory for a package.
#
# This function copies the contents from the most recently built versioned
# directory to a stable, non-versioned path (e.g., 'builds/core'). This
# provides a convenient way for developers to always access the latest build.
#
# @param $1: The name of the package (e.g., "core").
#
sync_latest() {
  local pkg_name="$1"
  # Read the version from the source package.json, which is the "latest" version by definition.
  local pkg_version=$(jq -r .version "packages/$pkg_name/package.json")
  local source_dir="builds/$pkg_name@$pkg_version"
  local dest_dir="builds/$pkg_name"

  echo "Syncing 'latest' directory for $pkg_name..."

  # Ensure the source directory from the current build exists before proceeding.
  if [ ! -d "$source_dir" ]; then
    echo "❌ SYNC FAILED: Source directory does not exist: $source_dir"
    exit 1
  fi

  # Remove the old "latest" directory to ensure a clean sync.
  rm -rf "$dest_dir"
  mkdir -p "$dest_dir"
  # Copy the contents. The '-a' flag preserves file attributes.
  cp -a "$source_dir"/* "$dest_dir/"

  echo "  ✔️  OK: Synced '$source_dir' to '$dest_dir'."
}


# --- Main Execution ---

echo "--- Phase 1: Packaging and Validating Versioned Builds ---"
mkdir -p builds
organize_package packages/core
organize_package packages/core-mt
organize_package packages/ffmpeg
organize_package packages/util
echo "✅ All packages were packaged and validated successfully."
echo ""

echo "--- Phase 2: Syncing 'Latest' Directories ---"
sync_latest core
sync_latest core-mt
sync_latest ffmpeg
sync_latest util
echo "✅ All 'latest' directories synced successfully."
echo ""

echo "--- Final Directory Structure ---"
ls -R builds