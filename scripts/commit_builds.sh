#!/bin/bash
#
# commit_builds.sh
#
# This script is responsible for committing the newly created build artifacts
# from the 'builds/' directory back into the Git repository.
#
# It dynamically generates a verbose, multi-line commit message and uses a
# robust method (piping to 'git commit -F -') to ensure correct formatting
# in the final Git history.
#

set -euo pipefail

echo "--- Committing and Pushing Builds ---"

# Configure the git user for this commit.
git config --global user.name "GitHub Actions"
git config --global user.email "actions@github.com"

# Add the entire 'builds' directory to the staging area.
git add builds/

# Check if there are any staged changes before proceeding.
if git diff --staged --quiet; then
  echo "✅ No changes to commit. Build artifacts are already up-to-date."
  exit 0
fi

echo "Changes detected in 'builds/' directory. Generating verbose commit message..."

# --- Generate Commit Message and Commit ---

# Read version numbers from each package.json
CORE_VERSION=$(jq -r .version "packages/core/package.json")
CORE_MT_VERSION=$(jq -r .version "packages/core-mt/package.json")
FFMPEG_VERSION=$(jq -r .version "packages/ffmpeg/package.json")
UTIL_VERSION=$(jq -r .version "packages/util/package.json")

# Get the current ISO 8601 timestamp.
DATETIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# --- REFACTOR: Store the output of the jq command in a variable ---
# This makes the script cleaner and separates data generation from formatting.
BUILD_DETAILS=$(jq -r '
  "Build Date: \(.buildDate)\n\n" +
  "Enabled Filters:\n" +
  "----------------\n" +
  (.enabledFilters | join("\n")) +
  "\n\n" +
  "Enabled Encoders:\n" +
  "-----------------\n" +
  (.enabledEncoders | join("\n")) +
  "\n\n" +
  "Enabled Decoders:\n" +
  "-----------------\n" +
  (.enabledDecoders | join("\n"))
' build-receipt.json)
# --- END REFACTOR ---

# Use printf to construct the entire multi-line message and pipe it to git commit.
# 'git commit -F -' reads the full commit message from standard input.
# This is the most reliable way to handle newlines and special characters.
printf "%s\n\n%s\n%s\n%s\n%s\n%s\n\n%s\n%s\n%s\n%s\n%s\n%s\n\n%s" \
  "ci: ${DATETIME} Build versions: core@${CORE_VERSION}, core-mt@${CORE_MT_VERSION}, ffmpeg@${FFMPEG_VERSION}, util@${UTIL_VERSION}" \
  "Packages Built:" \
  "----------------" \
  "- core@${CORE_VERSION}" \
  "- core-mt@${CORE_MT_VERSION}" \
  "- ffmpeg@${FFMPEG_VERSION}" \
  "- util@${UTIL_VERSION}" \
  "Build Artifact Paths:" \
  "---------------------" \
  "- builds/core@${CORE_VERSION}" \
  "- builds/core-mt@${CORE_MT_VERSION}" \
  "- builds/ffmpeg@${FFMPEG_VERSION}" \
  "- builds/util@${UTIL_VERSION}" \
  "${BUILD_DETAILS}" | git commit -F - # Use the new variable here

# Push the newly created commit.
git push

echo "✅ New builds successfully committed with a correctly formatted message."