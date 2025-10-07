#!/bin/bash
#
# FILE: build/ffmpeg-wasm-audio.sh
#
# DESCRIPTION:
#   This script is the final link-time step for the custom audio-only FFmpeg WASM build.
#   It uses the Emscripten compiler (emcc) to link the previously compiled FFmpeg libraries
#   into the final WebAssembly module (.wasm) and its JavaScript glue code (.js).
#
#   Its primary responsibilities are:
#   1. Defining the JavaScript interface (exported functions, memory settings).
#   2. Correctly linking against the required (and only the required) FFmpeg libraries.
#   3. Including the necessary C source files for the main ffmpeg program logic.
#
# USAGE:
#   This script is not intended to be run directly. It is invoked by the Makefile.
#   Example: ./build/ffmpeg-wasm-audio.sh -o ./packages/core/dist/ffmpeg-core.js
#
####################################################################################################

# Standard script header.
set -euo pipefail

# Defines the name of the exported JavaScript factory function.
# This will be the main entry point for developers using the library, e.g., `const core = await createFFmpegCore()`.
EXPORT_NAME="createFFmpegCore"

#
# CONF_FLAGS
# This array defines all the flags and source files passed to the Emscripten compiler (emcc).
#
CONF_FLAGS=(
  #-------------------------------------------------------------------------------------------------
  # SECTION 1: Include and Library Paths
  # These flags tell the Emscripten linker where to find header files (-I) and the compiled
  # FFmpeg static libraries (.a files) (-L). The order is important.
  #-------------------------------------------------------------------------------------------------
  -I.
  -I./src/fftools
  -I$INSTALL_DIR/include
  -L$INSTALL_DIR/lib
  -Llibavcodec
  -Llibavfilter
  -Llibavformat
  -Llibavutil
  -Llibswresample
  # CRITICAL: Paths to disabled video libraries (libavdevice, libpostproc, libswscale)
  # have been correctly removed to prevent linker errors.

  #-------------------------------------------------------------------------------------------------
  # SECTION 2: Library Linking Flags (-l)
  # These flags explicitly tell the linker which FFmpeg libraries to include in the final build.
  # The '-l' prefix is short for 'library'. For example, '-lavcodec' links libavcodec.a.
  # The order of these flags is critical; dependencies must come after the libraries that use them.
  #-------------------------------------------------------------------------------------------------
  -lavcodec
  -lavfilter
  -lavformat
  -lavutil
  -lswresample
  # CRITICAL: Linker flags for disabled video libraries (-lavdevice, -lpostproc, -lswscale)
  # have been correctly removed. Including them would result in "symbol not found" errors.

  #-------------------------------------------------------------------------------------------------
  # SECTION 3: Emscripten Environment and Feature Flags
  # These flags configure the WebAssembly environment and its capabilities.
  #-------------------------------------------------------------------------------------------------
  -Wno-deprecated-declarations # Suppress warnings about deprecated functions.
  $LDFLAGS                   # Include any additional linker flags passed from the environment.
  -sENVIRONMENT=worker       # Specifies the target environment, enabling use in Web Workers.
  -sWASM_BIGINT              # Enables BigInt support for handling 64-bit integers.
  -sUSE_SDL=2                # Includes SDL support, which is often used for basic I/O.
  -sSTACK_SIZE=5MB           # Sets the size of the program stack.
  -sMODULARIZE               # Wraps the output in a module for cleaner JavaScript usage.

  #-------------------------------------------------------------------------------------------------
  # SECTION 4: Memory and Threading Configuration
  # Conditionally set memory and threading options based on the build type (ST vs MT).
  #-------------------------------------------------------------------------------------------------
  # For Multi-Threaded (MT) builds, a larger initial memory block is required and a Pthread pool is created.
  ${FFMPEG_MT:+ -sINITIAL_MEMORY=1024MB}
  ${FFMPEG_MT:+ -sPTHREAD_POOL_SIZE=32}
  # For Single-Threaded (ST) builds, start with a smaller memory footprint but allow it to grow if needed.
  ${FFMPEG_ST:+ -sINITIAL_MEMORY=32MB -sALLOW_MEMORY_GROWTH}

  #-------------------------------------------------------------------------------------------------
  # SECTION 5: JavaScript Interface and Bindings
  # These flags define how the JavaScript world interacts with the compiled C code.
  #-------------------------------------------------------------------------------------------------
  -sEXPORT_NAME="$EXPORT_NAME" # Sets the name of the factory function.
  -sEXPORTED_FUNCTIONS=$(node src/bind/ffmpeg/export.js)             # Exports C functions to be callable from JS.
  -sEXPORTED_RUNTIME_METHODS=$(node src/bind/ffmpeg/export-runtime.js) # Exports Emscripten runtime methods.
  -lworkerfs.js              # Links the WorkerFS library for in-memory filesystem operations.
  --pre-js src/bind/ffmpeg/bind.js # Prepends custom JavaScript glue code to the output.

  #-------------------------------------------------------------------------------------------------
  # SECTION 6: Source Files for FFmpeg Program Logic
  # These C files contain the main entry point and command-line parsing logic for the `ffmpeg`
  # and `ffprobe` programs. They must be included now that `--disable-programs` has been removed
  # from the configuration step. This is what allows you to run commands like `ffmpeg -i input.mp3 ...`.
  #-------------------------------------------------------------------------------------------------
  src/fftools/cmdutils.c
  src/fftools/ffmpeg.c
  src/fftools/ffmpeg_filter.c
  src/fftools/ffmpeg_hw.c
  src/fftools/ffmpeg_mux.c
  src/fftools/ffmpeg_opt.c
  src/fftools/opt_common.c
  src/fftools/ffprobe.c
)

# Execute the final compilation and linking command.
# emcc is called with all the flags and source files defined above.
# "$@" passes through any additional arguments, such as the output file path (-o ...).
emcc "${CONF_FLAGS[@]}" "$@"