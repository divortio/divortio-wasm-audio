#!/bin/bash
#
# FILE: build/ffmpeg-audio.sh
#
# DESCRIPTION:
#   This script configures the FFmpeg source code for a custom, audio-only WebAssembly build.
#   It is designed to create a highly optimized, minimal-size library by explicitly disabling
#   all non-essential components (especially video) and enabling only a curated list of
#   audio codecs, filters, and formats. This script is called by 'emconfigure' which sets up
#   the appropriate environment for Emscripten (WASM compilation).
#
# USAGE:
#   This script is not intended to be run directly. It is invoked by the main project Makefile
#   as part of the custom audio build process, like so:
#   $ emconfigure ./build/ffmpeg-audio.sh
#
####################################################################################################

# Standard script header:
# 'set -e' ensures the script will exit immediately if a command fails.
# 'set -u' treats unset variables as an error.
# 'set -o pipefail' causes a pipeline to fail if any of its commands fail.
set -euo pipefail

#
# AUDIO_ONLY_FLAGS
# This array defines the core configuration for our minimal audio build. The strategy is to
# disable everything first (--disable-all) and then selectively re-enable only what is needed.
#
AUDIO_ONLY_FLAGS=(
  #-------------------------------------------------------------------------------------------------
  # SECTION 1: Foundational Disables
  # These flags form the baseline for our minimal build by removing major components.
  #-------------------------------------------------------------------------------------------------
  --disable-all           # Start by disabling every optional component.
  --disable-avdevice      # Disables platform-specific I/O devices (e.g., video4linux). Not needed for WASM.
  --disable-swscale       # Disables the video scaling and colorspace conversion library. CRITICAL for size reduction.
  --disable-postproc      # Disables video post-processing filters. CRITICAL for size reduction.
  --disable-network       # Disables network protocols (http, rtmp, etc.). Not typically needed for browser-based WASM.
  --disable-doc           # Disables building documentation.

  #-------------------------------------------------------------------------------------------------
  # SECTION 2: Core Component Enables
  # These are the essential FFmpeg libraries we need for any kind of media processing.
  #-------------------------------------------------------------------------------------------------
  --enable-avcodec        # Enable the core encoding/decoding library.
  --enable-avformat       # Enable the library for handling media container formats (muxing/demuxing).
  --enable-avfilter       # Enable the audio/video filtering library.
  --enable-swresample     # Enable the audio resampling, remixing, and format conversion library.

  #-------------------------------------------------------------------------------------------------
  # SECTION 3: External Libraries and Licensing
  # Enable specific, high-quality external audio encoders and their required licenses.
  #-------------------------------------------------------------------------------------------------
  --enable-gpl            # Required for linking against GPL-licensed libraries like libmp3lame.
  --enable-libmp3lame     # Enable the LAME MP3 encoder.
  --enable-libopus        # Enable the Opus audio encoder.

  #-------------------------------------------------------------------------------------------------
  # SECTION 4: Component-Level Granular Control
  # This section provides fine-grained control over which specific components are built into the
  # final library. This is a key part of the optimization strategy.
  #-------------------------------------------------------------------------------------------------
  # Enable only the specific encoders we need.
  --enable-encoder=libmp3lame,aac,libopus,flac,pcm_s16le
  # Enable the corresponding decoders.
  --enable-decoder=mp3,aac,opus,flac,pcm_s16le
  # Enable container format demuxers (for reading). 'mov' and 'matroska' are common containers for audio.
  --enable-demuxer=mov,matroska,mp3,ogg,flac,wav
  # Enable container format muxers (for writing).
  --enable-muxer=mp4,mp3,ogg,flac,wav
  # Enable parsers for elementary audio streams.
  --enable-parser=aac,flac,mpegaudio,opus

  #-------------------------------------------------------------------------------------------------
  # SECTION 5: Audio Filter Enables
  # Enable a specific set of audio filters required for your custom processing pipeline.
  #-------------------------------------------------------------------------------------------------
  --enable-filter=aformat,highpass,afftdn,deesser,loudnorm,astats,ametadata,adynamicequalizer,alimiter,agate,equalizer,asoftclip
)

#
# CONF_FLAGS
# This array assembles the final list of flags passed to FFmpeg's './configure' script.
# It includes standard Emscripten cross-compilation settings, optimization flags, and
# injects our custom AUDIO_ONLY_FLAGS array.
#
CONF_FLAGS=(
  #-------------------------------------------------------------------------------------------------
  # SECTION 1: Standard Cross-Compilation Flags
  # These are essential for telling FFmpeg that it's being compiled for a non-native target
  # (in this case, WebAssembly) using the Emscripten toolchain.
  #-------------------------------------------------------------------------------------------------
  --prefix=${PREFIX:-/src/dist} # The output directory for the compiled libraries.
  --target-os=none              # Specifies a "bare metal" target, appropriate for WASM.
  --arch=x86_32                 # Emscripten compiles to a 32-bit architecture.
  --enable-cross-compile        # Explicitly enable cross-compilation.
  --disable-asm                 # Disable assembly optimizations, as they are not applicable to WASM.
  --disable-stripping           # Do not strip symbols; this is handled later by the build process.
  --disable-debug               # Disable debugging symbols to reduce size.
  --disable-runtime-cpudetect   # Disable runtime CPU detection; not relevant in a WASM environment.
  --disable-autodetect          # Disable automatic detection of external libraries.

  #-------------------------------------------------------------------------------------------------
  # SECTION 2: Toolchain Configuration
  # Point the build process to the Emscripten compiler and tools. `ccache` is used to
  # speed up recompilation by caching previous results.
  #-------------------------------------------------------------------------------------------------
  --nm=emnm
  --ar=emar
  --ranlib=emranlib
  --cc="ccache emcc"
  --cxx="ccache em++"
  --objcc="ccache emcc"
  --dep-cc="ccache emcc"

  #-------------------------------------------------------------------------------------------------
  # SECTION 3: Performance Optimizations
  # These flags are passed to the C/C++ compiler to optimize for size and speed.
  #-------------------------------------------------------------------------------------------------
  --extra-cflags="-msimd128 -O3 -flto"      # Enable SIMD, use highest optimization level, and enable Link Time Optimization.
  --extra-ldflags="-msimd128 -O3 -flto"     # Pass the same flags to the linker.

  #-------------------------------------------------------------------------------------------------
  # SECTION 4: Threading Configuration
  # This line conditionally disables threading support if the FFMPEG_ST (single-threaded)
  # environment variable is set. This is crucial for creating separate ST and MT builds.
  #-------------------------------------------------------------------------------------------------
  ${FFMPEG_ST:+ --disable-pthreads --disable-w32threads --disable-os2threads}

  #-------------------------------------------------------------------------------------------------
  # SECTION 5: Inject Custom Audio Flags
  # The entire AUDIO_ONLY_FLAGS array is expanded and inserted here.
  #-------------------------------------------------------------------------------------------------
  "${AUDIO_ONLY_FLAGS[@]}"
)

# Execute the configuration command.
# 'emconfigure' is a wrapper that ensures the FFmpeg ./configure script is run with the
# correct environment variables and settings for Emscripten.
emconfigure ./configure "${CONF_FLAGS[@]}"

# After configuration is successful, run the build.
# 'emmake' is a wrapper for 'make' that ensures the Emscripten compiler (emcc) is used.
# The '-j' flag enables parallel compilation, significantly speeding up the build process.
emmake make -j