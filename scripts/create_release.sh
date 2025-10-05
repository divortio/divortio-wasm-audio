#!/bin/bash
#
# create_release.sh
#
# This script creates a formal GitHub Release, packaging build artifacts into
# flexible zip files and generating clean release notes.
#

set -euo pipefail

echo "--- Creating GitHub Release ---"

# --- Data Generation and Validation ---

if [ ! -d "builds" ]; then
  echo "❌ ERROR: 'builds' directory not found. Cannot create release."
  exit 1
fi

CORE_VERSION=$(jq -r .version "packages/core/package.json")
CORE_MT_VERSION=$(jq -r .version "packages/core-mt/package.json")
FFMPEG_VERSION=$(jq -r .version "packages/ffmpeg/package.json")
UTIL_VERSION=$(jq -r .version "packages/util/package.json")
DATETIME=$(date -u +"%Y%m%dT%H%M%SZ")
TAG="v${FFMPEG_VERSION}-${DATETIME}"

# --- Packaging Logic ---

echo "Packaging build artifacts for release..."
rm -rf release_assets
mkdir -p release_assets
mkdir -p release_assets/all-esm
mkdir -p release_assets/all-umd

find builds -mindepth 1 -maxdepth 1 -type d -name "*@*" | while read -r versioned_dir; do
  pkg_name_version=$(basename "$versioned_dir")
  pkg_name=$(echo "$pkg_name_version" | cut -d'@' -f1)
  find "$versioned_dir/dist" -mindepth 1 -maxdepth 1 -type d | while read -r module_dir; do
    module_type=$(basename "$module_dir")
    zip_filename="${pkg_name_version}-${module_type}.zip"
    (cd "$module_dir" && zip -r "../../../../release_assets/${zip_filename}" .)
    echo "  ✔️  Created individual package: ${zip_filename}"
    mkdir -p "release_assets/all-${module_type}/${pkg_name}"
    cp -a "$module_dir"/* "release_assets/all-${module_type}/${pkg_name}/"
  done
done

(cd release_assets/all-esm && zip -r ../ffmpeg-audio-build-esm.zip .)
echo "  ✔️  Created aggregate package: ffmpeg-audio-build-esm.zip"
(cd release_assets/all-umd && zip -r ../ffmpeg-audio-build-umd.zip .)
echo "  ✔️  Created aggregate package: ffmpeg-audio-build-umd.zip"
rm -rf release_assets/all-esm release_assets/all-umd

# --- Release Notes Generation ---

echo "Generating release notes..."
RELEASE_NOTES_FILE=$(mktemp)
cat <<EOF > "$RELEASE_NOTES_FILE"
### Packages Built
- \`core@${CORE_VERSION}\`
- \`core-mt@${CORE_MT_VERSION}\`
- \`ffmpeg@${FFMPEG_VERSION}\`
- \`util@${UTIL_VERSION}\`
EOF

# --- Release Creation and Upload ---

echo "Creating GitHub Release with tag: ${TAG}"
gh release create "$TAG" \
  --title "Build: ${TAG}" \
  --notes-file "$RELEASE_NOTES_FILE" \
  release_assets/*.zip

echo "✅ Successfully created GitHub Release: ${TAG}"