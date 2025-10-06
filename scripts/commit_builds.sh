#!/bin/bash
#
# commit_builds.sh
#
# This script is responsible for committing the newly created build artifacts
# from the 'builds/' directory back into the Git repository.
#
# It dynamically generates a verbose, multi-line commit message that includes:
#   - A succinct title with an ISO 8601 timestamp and a summary of versions.
#   - A detailed body listing the full path to each versioned build.
#   - A complete breakdown of all enabled filters, encoders, and decoders,
#     extracted from the build-receipt.json.
#
# This creates a rich, self-documenting history of each build's specific configuration.
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

# --- Generate Commit Message ---

# Read version numbers from each package.json
CORE_VERSION=$(jq -r .version "packages/core/package.json")
CORE_MT_VERSION=$(jq -r .version "packages/core-mt/package.json")
FFMPEG_VERSION=$(jq -r .version "packages/ffmpeg/package.json")
UTIL_VERSION=$(jq -r .version "packages/util/package.json")

# Get the current ISO 8601 timestamp.
DATETIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# 1. Construct the succinct commit title.
COMMIT_TITLE="ci: ${DATETIME} Build versions: core@${CORE_VERSION}, core-mt@${CORE_MT_VERSION}, ffmpeg@${FFMPEG_VERSION}, util@${UTIL_VERSION}"

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

# Add the detailed build receipt information.
COMMIT_BODY+=$(jq -r '
  "Build Date: \(.buildDate)\n\n" +
  "Enabled Filters:\n" +
  "----------------\n" +
  (.enabledFilters | map("- \(. | tostring)") | join("\n")) +
  "\n\n" +
  "Enabled Encoders:\n" +
  "-----------------\n" +
  (.enabledEncoders | map("- \(. | tostring)") | join("\n")) +
  "\n\n" +
  "Enabled Decoders:\n" +
  "-----------------\n" +
  (.enabledDecoders | map("- \(. | tostring)") | join("\n"))
' build-receipt.json)

# --- Commit and Push ---

# Use the -m flag twice to create a multi-line commit message.
# The first -m is the title, the second is the body.
git commit -m "$COMMIT_TITLE" -m "$COMMIT_BODY"
git push

echo "✅ New builds successfully committed with a verbose message."