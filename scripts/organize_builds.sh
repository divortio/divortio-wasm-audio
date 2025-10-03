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
#      build artifacts (like .wasm and .worker.js files) exist and are not
#      empty. If validation fails, the script will exit with an error.
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
# This function checks for the existence and non-zero size of critical files.
# For the multi-threaded core, it now robustly searches for the worker file
# anywhere within the 'dist' directory to handle variations in build output.
#
# @param $1: The path to the newly created versioned directory (e.g., "builds/core@0.12.10").
# @param $2: The name of the package (e.g., "core").
#
validate_package() {
  local target_dir="$1"
  local pkg_name="$2"
  # Use an associative array to map file names to their validation status.
  declare -A files_to_check

  echo "  - Running validation for $pkg_name..."
  echo "  - Contents of ${target_dir}/dist:"
  ls -R "${target_dir}/dist"

  # Define the critical files for each package.
  case "$pkg_name" in
    core)
      files_to_check["ffmpeg-core.wasm"]=false
      ;;
    core-mt)
      files_to_check["ffmpeg-core.wasm"]=false
      files_to_check["ffmpeg-core.worker.js"]=false
      ;;
    ffmpeg|util)
      files_to_check["index.js"]=false
      ;;
  esac

  # Search for the files within the entire dist directory.
  # The `find` command is more robust than a hardcoded path.
  for file in "${!files_to_check[@]}"; do
    # Find the file, check if it exists and has a size > 0.
    # The `-s` flag in `find` checks for non-empty files.
    found_path=$(find "$target_dir/dist" -name "$file" -type f -size +0c -print -quit)
    if [ -n "$found_path" ]; then
      files_to_check["$file"]=true
      local file_size=$(stat -c%s "$found_path")
      echo "  ✔️  OK: Found $found_path ($file_size bytes)."
    fi
  done

  # After searching, loop through our checklist and see if any file was not found.
  for file in "${!files_to_check[@]}"; do
    if [ "${files_to_check[$file]}" = false ]; then
      echo "❌ VALIDATION FAILED: Critical file is missing or empty: $file"
      exit 1
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
# @param $1: The name of the package (e.g., "core").
#
sync_latest() {
  local pkg_name="$1"
  local pkg_version=$(jq -r .version "packages/$pkg_name/package.json")
  local source_dir="builds/$pkg_name@$pkg_version"
  local dest_dir="builds/$pkg_name"

  echo "Syncing 'latest' directory for $pkg_name..."

  if [ ! -d "$source_dir" ]; then
    echo "❌ SYNC FAILED: Source directory does not exist: $source_dir"
    exit 1
  fi

  rm -rf "$dest_dir"
  mkdir -p "$dest_dir"
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