#!/bin/bash
#
# create_release.sh
#
# This script creates a formal GitHub Release, packaging build artifacts into
# a flexible set of downloadable zip files. It is designed to be run in the
# final job of the GitHub Actions workflow after all artifacts are built and
# organized.
#
# The script executes the following workflow:
#   1. Packages builds into individual ESM/UMD zip files and aggregate ESM/UMD zip files.
#   2. Generates a unique, versioned Git tag for the release.
#   3. Generates verbose, technical release notes from the build receipt.
#   4. Uses the GitHub CLI (gh) to create the release and upload all generated
#      zip files as release assets.
#

# --- Script Configuration ---

# Exit immediately if a command exits with a non-zero status.
set -euo pipefail


# --- Main Execution ---

echo "--- Creating GitHub Release ---"

# Input Validation: Ensure the 'builds' directory exists.
if [ ! -d "builds" ]; then
  echo "❌ ERROR: 'builds' directory not found. Cannot create release."
  exit 1
fi

# Find the build receipt, which is required for generating release notes.
# We'll use the single-threaded core package to locate it.
CORE_VERSION=$(jq -r .version "packages/core/package.json")
RECEIPT_PATH="builds/core@${CORE_VERSION}/build-receipt.json"
if [ ! -f "$RECEIPT_PATH" ]; then
  echo "❌ ERROR: Build receipt not found at '$RECEIPT_PATH'. Cannot generate release notes."
  exit 1
fi


# --- 1. Packaging Logic ---

echo "Packaging build artifacts for release..."
# Create a clean, temporary directory for our final zip assets.
rm -rf release_assets
mkdir -p release_assets
# Create temporary staging directories for the aggregate zips.
mkdir -p release_assets/all-esm
mkdir -p release_assets/all-umd

# Loop through each versioned package directory in 'builds/' (e.g., 'builds/core@0.12.10').
find builds -mindepth 1 -maxdepth 1 -type d -name "*@*" | while read -r versioned_dir; do
  pkg_name_version=$(basename "$versioned_dir") # e.g., "core@0.12.10"
  pkg_name=$(echo "$pkg_name_version" | cut -d'@' -f1) # e.g., "core"

  # Loop through 'esm' and 'umd' subdirectories.
  find "$versioned_dir/dist" -mindepth 1 -maxdepth 1 -type d | while read -r module_dir; do
    module_type=$(basename "$module_dir") # "esm" or "umd"

    # --- Create Individual Zip ---
    zip_filename="${pkg_name_version}-${module_type}.zip"
    (cd "$module_dir" && zip -r "../../../../release_assets/${zip_filename}" .)
    echo "  ✔️  Created individual package: ${zip_filename}"

    # --- Populate Aggregate Directories ---
    # Copy contents to the correct staging area (e.g., all-esm/core)
    mkdir -p "release_assets/all-${module_type}/${pkg_name}"
    cp -a "$module_dir"/* "release_assets/all-${module_type}/${pkg_name}/"
  done
done

# --- Create Aggregate Zips ---
(cd release_assets/all-esm && zip -r ../ffmpeg-audio-build-esm.zip .)
echo "  ✔️  Created aggregate package: ffmpeg-audio-build-esm.zip"
(cd release_assets/all-umd && zip -r ../ffmpeg-audio-build-umd.zip .)
echo "  ✔️  Created aggregate package: ffmpeg-audio-build-umd.zip"

# Clean up the temporary staging directories.
rm -rf release_assets/all-esm release_assets/all-umd


# --- 2. Release Tagging ---

FFMPEG_VERSION=$(jq -r .version "packages/ffmpeg/package.json")
DATETIME=$(date -u +"%Y%m%dT%H%M%SZ")
TAG="v${FFMPEG_VERSION}-${DATETIME}"
echo "Generated release tag: ${TAG}"


# --- 3. Verbose Release Notes ---

echo "Generating verbose release notes..."
CORE_MT_VERSION=$(jq -r .version "packages/core-mt/package.json")
UTIL_VERSION=$(jq -r .version "packages/util/package.json")
RELEASE_NOTES_FILE=$(mktemp)

cat <<EOF > "$RELEASE_NOTES_FILE"
### Packages Built
- \`core@${CORE_VERSION}\`
- \`core-mt@${CORE_MT_VERSION}\`
- \`ffmpeg@${FFMPEG_VERSION}\`
- \`util@${UTIL_VERSION}\`

---

$(jq -r '
  "### Build Details\n" +
  "**Build Date:** \(.buildDate)\n\n" +
  "**Enabled Filters:**\n" +
  "```\n" +
  (.enabledFilters | join("\n")) +
  "\n```\n\n" +
  "**Enabled Encoders:**\n" +
  "```\n" +
  (.enabledEncoders | join("\n")) +
  "\n```\n\n" +
  "**Enabled Decoders:**\n" +
  "```\n" +
  (.enabledDecoders | join("\n")) +
  "\n```"
' "$RECEIPT_PATH")
EOF


# --- 4. Release Creation and Upload ---

echo "Creating GitHub Release and uploading assets..."
# Use the GitHub CLI to create the release and upload all zip files.
# The GITHUB_TOKEN environment variable must be set in the workflow for authentication.
gh release create "$TAG" \
  --title "Build: ${TAG}" \
  --notes-file "$RELEASE_NOTES_FILE" \
  release_assets/*.zip

echo "✅ Successfully created GitHub Release: ${TAG}"