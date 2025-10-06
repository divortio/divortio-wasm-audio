#!/bin/bash
#
# build-wasm.sh
#
# This script acts as a wrapper around the 'make' command to correctly
# handle the passing of complex arguments for the Docker build. It avoids
# the shell quoting issues that arise when passing these arguments directly
# from the GitHub Actions YAML.
#
# Arguments:
#   $1 (TARGET): The 'make' target to execute (e.g., "build-st" or "build-mt").
#   $2 (CACHE_SUFFIX): A unique suffix for the cache paths (e.g., "st" or "mt").
#

set -euo pipefail

# --- Argument Validation ---
if [ "$#" -ne 2 ]; then
    echo "❌ ERROR: Illegal number of parameters."
    echo "Usage: $0 TARGET CACHE_SUFFIX"
    exit 1
fi

TARGET="$1"
CACHE_SUFFIX="$2"

echo "--- Building WASM Core via Wrapper Script ---"
echo "  - Target: ${TARGET}"
echo "  - Cache Suffix: ${CACHE_SUFFIX}"

# --- The Fix ---
# Construct the EXTRA_ARGS as a shell variable. When this is passed to 'make',
# the shell inside the Makefile will correctly parse it into distinct arguments.
EXTRA_ARGS="--mount=type=bind,source=$(pwd)/.ccache,target=/root/.ccache --cache-from=type=local,src=/tmp/.buildx-cache-${CACHE_SUFFIX} --cache-to=type=local,dest=/tmp/.buildx-cache-${CACHE_SUFFIX},mode=max"

# Execute the make command, passing the arguments as a make variable.
make -j "${TARGET}" EXTRA_ARGS="${EXTRA_ARGS}"

echo "✅ Successfully executed make target: ${TARGET}"