#!/bin/bash
#
# build-js-package.sh
#
# This script builds a specific variant (ESM or UMD) of a single JavaScript
# package. It has been updated to handle the build dependency chain and the
# correct working directory for Webpack.
#
# Arguments:
#   $1 (PACKAGE_NAME): The name of the package to build (e.g., "util", "ffmpeg").
#   $2 (FORMAT): The module format to build (e.g., "esm", "umd").
#

set -euo pipefail

# --- Argument Validation ---
if [ "$#" -ne 2 ]; then
    echo "❌ ERROR: Illegal number of parameters."
    echo "Usage: $0 PACKAGE_NAME FORMAT"
    exit 1
fi

PACKAGE_NAME="$1"
FORMAT="$2"

echo "--- Building JS Package ---"
echo "  - Package: @ffmpeg/${PACKAGE_NAME}"
echo "  - Format:  ${FORMAT}"

# --- Build Logic ---
case "$PACKAGE_NAME" in
  util)
    case "$FORMAT" in
      esm)
        # For ESM, we can run tsc from the root as its config paths are explicit.
        npx tsc --build "packages/util/tsconfig.esm.json"
        ;;
      umd)
        # The UMD build (using Webpack) depends on the CJS build.
        echo "  - Building CJS dependency for UMD bundle..."
        npx tsc --build "packages/util/tsconfig.cjs.json"

        # --- THIS IS THE CRITICAL FIX ---
        # We must change into the package's directory before running webpack
        # so that its relative config paths resolve correctly.
        echo "  - Building UMD bundle with Webpack..."
        (cd "packages/util" && npx webpack)
        ;;
      *)
        echo "❌ ERROR: Invalid format '$FORMAT' for package '$PACKAGE_NAME'."
        exit 1
        ;;
    esac
    ;;
  ffmpeg)
    case "$FORMAT" in
      esm)
        npx tsc --build "packages/ffmpeg/tsconfig.esm.json"
        ;;
      umd)
        # Apply the same fix for the ffmpeg package's UMD build.
        echo "  - Building UMD bundle with Webpack..."
        (cd "packages/ffmpeg" && npx webpack)
        ;;
      *)
        echo "❌ ERROR: Invalid format '$FORMAT' for package '$PACKAGE_NAME'."
        exit 1
        ;;
    esac
    ;;
  *)
    echo "❌ ERROR: Invalid package name '$PACKAGE_NAME'."
    exit 1
    ;;
esac

echo "✅ Successfully built @ffmpeg/${PACKAGE_NAME} in ${FORMAT} format."