#!/bin/bash
#
# build-js-package.sh
#
# This script builds a specific variant (ESM or UMD) of a single JavaScript
# package. It has been updated to handle the build dependency chain where the
# UMD build of @ffmpeg/util requires a CJS build to be completed first.
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
        # For ESM, we use the TypeScript compiler (tsc) with the ESM tsconfig.
        npx tsc --build "packages/util/tsconfig.esm.json"
        ;;
      umd)
        # --- THIS IS THE CRITICAL FIX ---
        # The UMD build (using Webpack) depends on the CJS build being completed first.
        # We now run both commands in the correct order.
        echo "  - Building CJS dependency for UMD bundle..."
        npx tsc --build "packages/util/tsconfig.cjs.json"

        echo "  - Building UMD bundle with Webpack..."
        npx webpack --config "packages/util/webpack.config.cjs"
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
        # The ffmpeg package does not have the same dependency chain.
        npx tsc --build "packages/ffmpeg/tsconfig.esm.json"
        ;;
      umd)
        npx webpack --config "packages/ffmpeg/webpack.config.js"
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