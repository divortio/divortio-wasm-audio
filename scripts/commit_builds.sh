#!/bin/bash
#
# commit_builds.sh
#
# This script is responsible for committing the newly created build artifacts
# from the 'builds/' directory back into the Git repository.
#
# It first configures a git user identity for the commit, then adds the entire
# 'builds' directory to the staging area. To prevent empty, redundant commits,
# it checks if there are any actual changes to be committed before proceeding.
# If changes are detected, it creates a commit and pushes it to the 'main'
# branch of the repository.
#

set -euo pipefail

echo "--- Committing and Pushing Builds ---"

# Configure the git user for this commit.
# This identity is used in the commit log.
git config --global user.name "GitHub Actions"
git config --global user.email "actions@github.com"

# Add the entire 'builds' directory to the staging area.
git add builds/

# Check if there are any staged changes.
# The 'git diff --staged --quiet' command exits with 0 if there are no changes,
# and 1 if there are changes. The '!' negates this, so the block only
# runs if there are changes to commit.
if ! git diff --staged --quiet; then
  echo "Changes detected in 'builds/' directory. Committing and pushing..."
  git commit -m "ci: Add latest builds"
  git push
  echo "✅ New builds successfully committed."
else
  echo "✅ No changes to commit. Build artifacts are already up-to-date."
fi