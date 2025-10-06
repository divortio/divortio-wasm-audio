#!/bin/bash
set -e

TARGET=$1
CACHE_SUFFIX=$2

echo "--- Building WASM Core via Wrapper Script ---"
echo "  - Target: ${TARGET}"
echo "  - Cache Suffix: ${CACHE_SUFFIX}"

# This is the full string of extra arguments for Docker
EXTRA_ARGS="--mount=type=bind,source=${PWD}/.ccache,target=/root/.ccache --cache-from=type=local,src=/tmp/.buildx-cache-${CACHE_SUFFIX} --cache-to=type=local,dest=/tmp/.buildx-cache-${CACHE_SUFFIX},mode=max"

# Execute make directly instead of using eval.
# This is more reliable and correctly handles the environment and arguments.
# The BUILDX_BUILDER variable is passed automatically from the GitHub Actions env.
make -j "${TARGET}" \
  BUILDX_BUILDER="${BUILDX_BUILDER}" \
  EXTRA_ARGS="${EXTRA_ARGS}"