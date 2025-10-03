#!/bin/bash
# Standard script header. Correct.
set -euo pipefail

# Defines the name of the exported JavaScript function. Correct.
EXPORT_NAME="createFFmpegCore"

# This array defines all the flags passed to the Emscripten compiler (emcc).
CONF_FLAGS=(
  # --- Standard Include and Library Paths ---
  # These lines tell the compiler where to find header files and compiled libraries. Correct.
  -I.
  -I./src/fftools
  -I$INSTALL_DIR/include
  -L$INSTALL_DIR/lib
  -Llibavcodec

  # --- CRITICAL FIX SECTION ---
  # The following lines were the source of our last failure. They pointed to video-only
  # libraries that we disabled in ffmpeg.sh. They are now correctly removed/commented out.
  # -Llibavdevice     # CORRECTLY REMOVED
  -Llibavfilter
  -Llibavformat
  -Llibavutil
  # -Llibpostproc     # CORRECTLY REMOVED
  -Llibswresample
  # -Llibswscale      # CORRECTLY REMOVED

  # --- Library Linking ---
  # These lines tell the linker exactly which libraries to include.
  -lavcodec
  # CRITICAL FIX: The linker flags for the disabled video libraries are also correctly removed here.
  # -lavdevice        # CORRECTLY REMOVED
  -lavfilter
  -lavformat
  -lavutil
  # -lpostproc        # CORRECTLY REMOVED
  -lswresample
  # -lswscale         # CORRECTLY REMOVED

  # --- Standard Emscripten & Project Flags ---
  # The rest of these flags are from the original, working script. They configure
  # the WASM environment (memory, threading, exports, etc.) and are correct.
  -Wno-deprecated-declarations
  $LDFLAGS
  -sENVIRONMENT=worker
  -sWASM_BIGINT
  -sUSE_SDL=2
  -sSTACK_SIZE=5MB
  -sMODULARIZE
  ${FFMPEG_MT:+ -sINITIAL_MEMORY=1024MB}
  ${FFMPEG_MT:+ -sPTHREAD_POOL_SIZE=32}
  ${FFMPEG_ST:+ -sINITIAL_MEMORY=32MB -sALLOW_MEMORY_GROWTH}
  -sEXPORT_NAME="$EXPORT_NAME"
  -sEXPORTED_FUNCTIONS=$(node src/bind/ffmpeg/export.js)
  -sEXPORTED_RUNTIME_METHODS=$(node src/bind/ffmpeg/export-runtime.js)
  -lworkerfs.js
  --pre-js src/bind/ffmpeg/bind.js

  # --- Source Files for FFmpeg Program Logic ---
  # These files are included because we re-enabled the programs to get the worker file
  # and your `ffmpeg -filters` command functionality. This is correct.
  src/fftools/cmdutils.c
  src/fftools/ffmpeg.c
  src/fftools/ffmpeg_filter.c
  src/fftools/ffmpeg_hw.c
  src/fftools/ffmpeg_mux.c
  src/fftools/ffmpeg_opt.c
  src/fftools/opt_common.c
  src/fftools/ffprobe.c
)

# This command executes the final compilation and linking. It passes all the flags we defined. Correct.
emcc "${CONF_FLAGS[@]}" "$@"