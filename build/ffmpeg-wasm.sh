#!/bin/bash
#
# ffmpeg-wasm.sh
#
# This script is the final link stage, calling the Emscripten compiler (emcc)
# to package the compiled libraries into the final .wasm and .js files.
#
# This final version includes the critical flags required by Emscripten to
# correctly generate the multi-threading worker file.
#

set -euo pipefail

EXPORT_NAME="createFFmpegCore"

# --- THIS IS THE CRITICAL FIX ---
# Define an empty array for thread flags.
THREAD_FLAGS=()
# If the FFMPEG_MT environment variable is set (which it is for the MT build),
# populate the array with the flags required by Emscripten for multi-threading.
if [ -n "${FFMPEG_MT:-}" ]; then
  THREAD_FLAGS=(
    -sUSE_PTHREADS=1
    -sPTHREAD_POOL_SIZE=32
    -sINITIAL_MEMORY=1024MB
  )
fi
# --- END OF FIX ---

CONF_FLAGS=(
  -I.
  -I./src/fftools
  -I$INSTALL_DIR/include
  -L$INSTALL_DIR/lib
  -Llibavcodec
  -Llibavfilter
  -Llibavformat
  -Llibavutil
  -Llibswresample
  -lavcodec
  -lavfilter
  -lavformat
  -lavutil
  -lswresample
  -Wno-deprecated-declarations
  $LDFLAGS
  -sENVIRONMENT=worker
  -sWASM_BIGINT
  -sUSE_SDL=2
  -sSTACK_SIZE=5MB
  -sMODULARIZE
  # The old, insufficient flags are removed in favor of the THREAD_FLAGS array.
  ${FFMPEG_ST:+ -sINITIAL_MEMORY=32MB -sALLOW_MEMORY_GROWTH}
  -sEXPORT_NAME="$EXPORT_NAME"
  -sEXPORTED_FUNCTIONS=$(node src/bind/ffmpeg/export.js)
  -sEXPORTED_RUNTIME_METHODS=$(node src/bind/ffmpeg/export-runtime.js)
  -lworkerfs.js
  --pre-js src/bind/ffmpeg/bind.js
  # Source files for the ffmpeg program logic.
  src/fftools/cmdutils.c
  src/fftools/ffmpeg.c
  src/fftools/ffmpeg_filter.c
  src/fftools/ffmpeg_hw.c
  src/fftools/ffmpeg_mux.c
  src/fftools/ffmpeg_opt.c
  src/fftools/opt_common.c
  src/fftools/ffprobe.c
  # Inject the thread flags into the final command.
  "${THREAD_FLAGS[@]}"
)

emcc "${CONF_FLAGS[@]}" "$@"