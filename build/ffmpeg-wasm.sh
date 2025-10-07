#!/bin/bash
#
# FILE: build/ffmpeg-wasm.sh
#
# DESCRIPTION:
#   This is a modified version of the official ffmpeg-wasm.sh script, tailored
#   for a custom, audio-only build. All modifications are done by commenting out
#   unnecessary lines and adding the required audio configuration, preserving
#   the original structure for clarity and maintenance.
#
# VERSION: 2.0
#
# CHANGE LOG:
#   - v2.0:
#     - Based on the user-provided official script.
#     - Modified the CONF_FLAGS array to explicitly link only the required
#       audio libraries, removing the dependency on Docker environment variables.
#     - Commented out all linker flags related to video libraries that were
#       disabled in our custom Dockerfile.
#
####################################################################################################

# `-o <OUTPUT_FILE_NAME>` must be provided when using this build script.
# ex:
#     bash ffmpeg-wasm.sh -o ffmpeg.js

set -euo pipefail

EXPORT_NAME="createFFmpegCore"

CONF_FLAGS=(
  -I.
  -I./src/fftools
  -I$INSTALL_DIR/include
  -L$INSTALL_DIR/lib
  -Llibavcodec
  # -Llibavdevice       # Commented out: Not used in audio-only build
  -Llibavfilter
  -Llibavformat
  -Llibavutil
  # -Llibpostproc       # Commented out: Not used in audio-only build
  -Llibswresample
  # -Llibswscale        # Commented out: Not used in audio-only build

  # --- Custom Audio Library Linker Flags ---
  # These flags explicitly link the audio libraries we compiled in the Dockerfile.
  -lmp3lame
  -lopus
  -lvorbis
  -logg
  # --- End Custom Flags ---

  -lavcodec
  # -lavdevice          # Commented out: Not used in audio-only build
  -lavfilter
  -lavformat
  -lavutil
  # -lpostproc          # Commented out: Not used in audio-only build
  -lswresample
  # -lswscale           # Commented out: Not used in audio-only build
  -Wno-deprecated-declarations
  # $LDFLAGS            # Commented out: Replaced with explicit flags above for clarity
  -sENVIRONMENT=worker
  -sWASM_BIGINT                            # enable big int support
  -sUSE_SDL=2                              # use emscripten SDL2 lib port
  -sSTACK_SIZE=5MB                         # increase stack size to support libopus
  -sMODULARIZE                             # modularized to use as a library
  ${FFMPEG_MT:+ -sINITIAL_MEMORY=1024MB}   # ALLOW_MEMORY_GROWTH is not recommended when using threads, thus we use a large initial memory
  ${FFMPEG_MT:+ -sPTHREAD_POOL_SIZE=32}    # use 32 threads
  ${FFMPEG_ST:+ -sINITIAL_MEMORY=32MB -sALLOW_MEMORY_GROWTH} # Use just enough memory as memory usage can grow
  -sEXPORT_NAME="$EXPORT_NAME"             # required in browser env, so that user can access this module from window object
  -sEXPORTED_FUNCTIONS=$(node src/bind/ffmpeg/export.js) # exported functions
  -sEXPORTED_RUNTIME_METHODS=$(node src/bind/ffmpeg/export-runtime.js) # exported built-in functions
  -lworkerfs.js
  --pre-js src/bind/ffmpeg/bind.js        # extra bindings, contains most of the ffmpeg.wasm javascript code
  # ffmpeg source code
  src/fftools/cmdutils.c
  src/fftools/ffmpeg.c
  src/fftools/ffmpeg_filter.c
  src/fftools/ffmpeg_hw.c
  src/fftools/ffmpeg_mux.c
  src/fftools/ffmpeg_opt.c
  src/fftools/opt_common.c
  src/fftools/ffprobe.c
)

emcc "${CONF_FLAGS[@]}" "$@"