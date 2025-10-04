#!/bin/bash
#
# build-js-package.sh
#
# This script builds a specific variant (ESM or UMD) of a single JavaScript
# package (@ffmpeg/util or @ffmpeg/ffmpeg). It is designed to be called by a
# reusable GitHub Actions workflow.
#
# This approach allows for granular, parallel builds of the JS packages without
# modifying the upstream package.json files, as we can invoke the TypeScript
# compiler (tsc) and Webpack directly with the correct configurations.
#
# Arguments:
#   $1 (PACKAGE_NAME): The name of the package to build (e.g., "util", "ffmpeg").
#   $2 (FORMAT): The module format to build (e.g., "esm", "umd").
#
# Usage:
#   ./scripts/build-js-package.sh util esm
#   ./scripts/build-js-package.sh ffmpeg umd
#

# --- Script Configuration ---
set -euo pipefail

# --- Argument Validation ---
if [ "$#" -ne 2 ]; then
    echo "❌ ERROR: Illegal number of parameters."
    echo "Usage: $0 PACKAGE_NAME FORMAT"
    echo "Example: $0 util esm"
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
        # For ESM, we use the TypeScript compiler (tsc) with the specific tsconfig.esm.json.
        npx tsc --build "packages/util/tsconfig.esm.json"
        ;;
      umd)
        # For UMD, we use Webpack to bundle the code for multiple module systems.
        npx webpack --config "packages/util/webpack.config.cjs"
        ;;
      *)
        echo "❌ ERROR: Invalid format '$FORMAT' for package '$PACKAGE_NAME'. Must be 'esm' or 'umd'."
        exit 1
        ;;
    esac
    ;;
  ffmpeg)
    case "$FORMAT" in
      esm)
        # Similar to the 'util' package, we use tsc for the ESM build.
        npx tsc --build "packages/ffmpeg/tsconfig.esm.json"
        ;;
      umd)
        # And Webpack for the UMD build.
        npx webpack --config "packages/ffmpeg/webpack.config.js"
        ;;
      *)
        echo "❌ ERROR: Invalid format '$FORMAT' for package '$PACKAGE_NAME'. Must be 'esm' or 'umd'."
        exit 1
        ;;
    esac
    ;;
  *)
    echo "❌ ERROR: Invalid package name '$PACKAGE_NAME'. Must be 'util' or 'ffmpeg'."
    exit 1
    ;;
esac

echo "✅ Successfully built @ffmpeg/${PACKAGE_NAME} in ${FORMAT} format."