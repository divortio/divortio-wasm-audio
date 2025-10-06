#!/bin/bash
#
# build-wasm.sh
#
# This script constructs and executes the full 'make' command using 'eval'.
# This is the standard, robust method for solving complex shell quoting and
# expansion issues when calling a command that takes dynamic arguments.
# It ensures that all arguments are parsed correctly by the shell before
# the 'make' command is invoked, bypassing the interpretation issues
# between the GitHub Actions runner, make, and the Makefile's sub-shell.
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

# 1. Construct the arguments string. Note the escaped double quotes.
#    This ensures the make variable itself is a single quoted string.
ARGS="--mount=type=bind,source=${PWD}/.ccache,target=/root/.ccache --cache-from=type=local,src=/tmp/.buildx-cache-${CACHE_SUFFIX} --cache-to=type=local,dest=/tmp/.buildx-cache-${CACHE_SUFFIX},mode=max"

# 2. Construct the full command to be executed, with the ARGS properly quoted for make.
CMD="make -j ${TARGET} EXTRA_ARGS=\"${ARGS}\""

# 3. Use 'eval' to execute the command string.
#    'eval' forces the shell to perform a second pass of parsing, correctly
#    interpreting the quotes and expanding the variables as intended.
echo "Executing command with eval: ${CMD}"
eval "${CMD}"

echo "✅ Successfully executed make target: ${TARGET}"