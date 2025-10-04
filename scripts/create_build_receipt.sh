#!/bin/bash

set -euo pipefail

echo "Generating build-receipt.json..."

# Source the ffmpeg.sh script to get access to its variables.
# The ':-""' prevents "unbound variable" errors if FFMPEG_ST is not set.
FFMPEG_ST="${FFMPEG_ST:-}"
source build/ffmpeg.sh

# Initialize empty arrays for our findings.
FILTERS=()
ENCODERS=()
DECODERS=()

# Loop through every flag defined in the AUDIO_ONLY_FLAGS array.
for flag in "${AUDIO_ONLY_FLAGS[@]}"; do
  # Use a case statement for robust parsing.
  case "$flag" in
    --enable-filter=*)
      # Extract the value after the '=' and add it to the FILTERS array.
      FILTERS+=("${flag#*=}")
      ;;
    --enable-encoder=*)
      # Split the comma-separated list and add each item to the ENCODERS array.
      IFS=',' read -r -a encoder_list <<< "${flag#*=}"
      for encoder in "${encoder_list[@]}"; do
        ENCODERS+=("$encoder")
      done
      ;;
    --enable-decoder=*)
      # Split the comma-separated list and add each item to the DECODERS array.
      IFS=',' read -r -a decoder_list <<< "${flag#*=}"
      for decoder in "${decoder_list[@]}"; do
        DECODERS+=("$decoder")
      done
      ;;
  esac
done

BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Use jq to build the final JSON from our bash arrays.
jq -n \
  --arg date "$BUILD_DATE" \
  --argjson filters "$(printf '%s\n' "${FILTERS[@]}" | jq -R . | jq -s .)" \
  --argjson encoders "$(printf '%s\n' "${ENCODERS[@]}" | jq -R . | jq -s .)" \
  --argjson decoders "$(printf '%s\n' "${DECODERS[@]}" | jq -R . | jq -s .)" \
  '{
    "buildDate": $date,
    "enabledFilters": $filters,
    "enabledEncoders": $encoders,
    "enabledDecoders": $decoders
  }' > build-receipt.json

echo "Receipt generated:"
cat build-receipt.json