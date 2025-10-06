#!/bin/bash
#
# create_release.sh
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

## Create a single, all-inclusive zip file.
#(cd builds && zip -r "../release_assets/ffmpeg-audio-build-all.zip" .)
#echo "  ✔️  Created all-in-one package: ffmpeg-audio-build-all.zip"


# --- 2. Release Tagging ---

# Construct the f
# --- 3. Verbose Release Notes ---

echo "Generating verbose release notes..."

# Read version numbers from each package.json
CORE_VERSION=$(jq -r .version "packages/core/package.json")
CORE_MT_VERSION=$(jq -r .version "packages/core-mt/package.json")
FFMPEG_VERSION=$(jq -r .version "packages/ffmpeg/package.json")
UTIL_VERSION=$(jq -r .version "packages/util/package.json")

# Get the current ISO 8601 timestamp.
DATETIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")


TAG="v${FFMPEG_VERSION}-${DATETIME}"
echo "Generated release tag: ${TAG}"


# 2. Construct the commit body.
# Start with a newline to separate it from the title.
COMMIT_BODY=$'\\n'

# Add the "Packages Built" section.
COMMIT_BODY+="CI BUILD:${DATETIME}| \\n"
COMMIT_BODY+="----------------\\n"
COMMIT_BODY+="- core@${CORE_VERSION}\\n"
COMMIT_BODY+="- core-mt@${CORE_MT_VERSION}\\n"
COMMIT_BODY+="- ffmpeg@${FFMPEG_VERSION}\\n"
COMMIT_BODY+="- util@${UTIL_VERSION}\\n\\n"

# Add the "Build Artifact Paths" section.
COMMIT_BODY+="Build Artifact Paths:\\n"
COMMIT_BODY+="---------------------\\n"
COMMIT_BODY+="- builds/core@${CORE_VERSION}\\n"
COMMIT_BODY+="- builds/core-mt@${CORE_MT_VERSION}\\n"
COMMIT_BODY+="- builds/ffmpeg@${FFMPEG_VERSION}\\n"
COMMIT_BODY+="- builds/util@${UTIL_VERSION}\\n\\n"

# Use a temporary file to store the multi-line release notes.
RELEASE_NOTES_FILE=$(mktemp)

# Construct the release body.
# Using 'cat <<EOF' is a robust way to handle multi-line strings in bash.
cat <<EOF > "$RELEASE_NOTES_FILE"
${COMMIT_BODY}
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