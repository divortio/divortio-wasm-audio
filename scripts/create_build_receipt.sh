#!/bin/bash

set -euo pipefail

echo "Generating build-receipt.json..."

# Gracefully get filter, encoder, and decoder text, defaulting to an empty string if not found
FILTERS_TEXT=$(grep -o '\\--enable-filter=[^ ]*' build/ffmpeg.sh | cut -d '=' -f 2 | tr '\n' ',' | sed 's/,$//') || true
ENCODERS_TEXT=$(grep -o '\\--enable-encoder=[^ ]*' build/ffmpeg.sh | cut -d '=' -f 2) || true
DECODERS_TEXT=$(grep -o '\\--enable-decoder=[^ ]*' build/ffmpeg.sh | cut -d '=' -f 2) || true
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

jq -n \
  --arg filters "$FILTERS_TEXT" \
  --arg encoders "$ENCODERS_TEXT" \
  --arg decoders "$DECODERS_TEXT" \
  --arg date "$BUILD_DATE" \
  '{
    "buildDate": $date,
    "enabledFilters": (if $filters == "" or $filters == null then [] else $filters | split(",") end),
    "enabledEncoders": (if $encoders == "" or $encoders == null then [] else $encoders | split(",") end),
    "enabledDecoders": (if $decoders == "" or $decoders == null then [] else $decoders | split(",") end)
  }' > build-receipt.json

echo "Receipt generated:"
cat build-receipt.json