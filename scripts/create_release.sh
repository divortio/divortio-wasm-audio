#!/bin/bash
#
# create_release.sh
#
# This script is responsible for creating a formal GitHub Release after a
# successful build and commit. It is designed to be run in the final job
# of the GitHub Actions workflow.
#
# The script performs four main functions:
#   1. Packaging: It creates individual, versioned zip files for each package
#      (core, core-mt, ffmpeg, util) as well as a single, all-inclusive zip file.
#   2. Tagging: It generates a unique Git tag for the release, combining the
#      @ffmpeg/ffmpeg version with a UTC timestamp for uniqueness.
#   3. Release Notes Generation: It constructs a verbose, multi-line description
#      for the release, including package versions, artifact paths, and a full
#      list of enabled filters, encoders, and decoders from the build receipt.
#   4. Release Creation & Upload: It uses the GitHub CLI (gh) to create the
#      tag, create the release, and upload all the generated zip files as
#      downloadable release assets.
#

# --- Script Configuration ---

# Exit immediately if a command exits with a non-zero status.
set -euo pipefail

# --- Main Execution ---

echo "--- Creating GitHub Release ---"

# Check if the builds directory exists before proceeding.
if [ ! -d "builds" ]; then
  echo "❌ ERROR: 'builds' directory not found. Cannot create release."
  exit 1
fi

# The build receipt must exist in the root of a core package.
# We'll use the single-threaded core to find it.
CORE_VERSION=$(jq -r .version "packages/core/package.json")
RECEIPT_PATH="builds/core@${CORE_VERSION}/build-receipt.json"

if [ ! -f "$RECEIPT_PATH" ]; then
  echo "❌ ERROR: Build receipt not found at '$RECEIPT_PATH'. Cannot generate release notes."
  exit 1
fi


# --- 1. Packaging Logic ---

echo "Packaging build artifacts..."
# Create a temporary directory for our zip files.
mkdir -p release_assets

# Find all versioned directories inside 'builds/'.
# The `-mindepth 1 -maxdepth 1` ensures we only get the top-level package directories.
find builds -mindepth 1 -maxdepth 1 -type d | while read -r dir; do
  # Get the directory name (e.g., "core@0.12.10").
  dirname=$(basename "$dir")
  # Create a zip file for this individual package.
  (cd "$dir" && zip -r "../../release_assets/${dirname}.zip" .)
  echo "  ✔️  Created individual package: ${dirname}.zip"
done

# Create a single, all-inclusive zip file.
(cd builds && zip -r "../release_assets/ffmpeg-audio-build-all.zip" .)
echo "  ✔️  Created all-in-one package: ffmpeg-audio-build-all.zip"


# --- 2. Release Tagging ---

# Read the version from the main ffmpeg package to use in the tag.
FFMPEG_VERSION=$(jq -r .version "packages/ffmpeg/package.json")
# Get the current ISO 8601 timestamp for uniqueness.
DATETIME=$(date -u +"%Y%m%dT%H%M%SZ")
# Construct the final Git tag.
TAG="v${FFMPEG_VERSION}-${DATETIME}"
echo "Generated release tag: ${TAG}"


# --- 3. Verbose Release Notes ---

echo "Generating verbose release notes..."
# This logic is reused and enhanced from the commit_builds.sh script.
CORE_MT_VERSION=$(jq -r .version "packages/core-mt/package.json")
UTIL_VERSION=$(jq -r .version "packages/util/package.json")

# Use a temporary file to store the multi-line release notes.
RELEASE_NOTES_FILE=$(mktemp)

# Construct the release body.
# Using 'cat <<EOF' is a robust way to handle multi-line strings in bash.
cat <<EOF > "$RELEASE_NOTES_FILE"
### Packages Built
- \`core@${CORE_VERSION}\`
- \`core-mt@${CORE_MT_VERSION}\`
- \`ffmpeg@${FFMPEG_VERSION}\`
- \`util@${UTIL_VERSION}\`

### Build Artifact Paths (in repository)
- \`builds/core@${CORE_VERSION}\`
- \`builds/core-mt@${CORE_MT_VERSION}\`
- \`builds/ffmpeg@${FFMPEG_VERSION}\`
- \`builds/util@${UTIL_VERSION}\`

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

# Use the GitHub CLI to create the release.
# The GITHUB_TOKEN environment variable must be set in the workflow.
gh release create "$TAG" \
  --title "Build: ${TAG}" \
  --notes-file "$RELEASE_NOTES_FILE" \
  release_assets/*.zip

echo "✅ Successfully created GitHub Release: ${TAG}"