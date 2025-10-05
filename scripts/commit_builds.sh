#!/bin/bash
#
# commit_builds.sh
#
# This script commits the newly created build artifacts from the 'builds/'
# directory back into the Git repository.
#
# It generates a clean, multi-line commit message that includes the version
# numbers of all packages built in this run and the paths to their artifacts.
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

echo "Changes detected in 'builds/' directory. Generating commit message..."

# --- Generate Commit Message and Commit ---

# Read version numbers from each package.json
CORE_VERSION=$(jq -r .version "packages/core/package.json")
CORE_MT_VERSION=$(jq -r .version "packages/core-mt/package.json")
FFMPEG_VERSION=$(jq -r .version "packages/ffmpeg/package.json")
UTIL_VERSION=$(jq -r .version "packages/util/package.json")
DATETIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Use printf to construct the multi-line message and pipe it to git commit.
printf "%s\n\n%s\n%s\n%s\n%s\n%s\n\n%s\n%s\n%s\n%s\n%s\n%s" \
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
  "- builds/util@${UTIL_VERSION}" | git commit -F -

# Push the newly created commit.
git push

echo "✅ New builds successfully committed."