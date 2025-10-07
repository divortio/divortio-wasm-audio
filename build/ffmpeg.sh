#!/bin/bash
#
# FILE: build/ffmpeg.sh
#
# DESCRIPTION:
#   This is a modified version of the official ffmpeg.sh script, tailored
#   for a custom, audio-only build. It follows all user-provided best
#   practices for clarity and correctness.
#
# VERSION: 5.0
#
# CHANGE LOG:
#   - v5.0:
#     - CORRECTED: Resolved IDE warning by splitting comma-separated lists
#       for encoders, decoders, etc., into individual flags, using spaces
#       as the array separator. This adheres to shell scripting best practices.
#
####################################################################################################

set -euo pipefail

CONF_FLAGS=(
  # --- Custom Audio-Only Build Configuration ---
  --disable-all
  --disable-avdevice
  --disable-swscale
  --disable-postproc
  --disable-network
  --disable-doc
  # --- Enable essential components ---
  --enable-avcodec
  --enable-avformat
  --enable-avfilter
  --enable-swresample
  # --- Enable external libraries & licenses ---
  --enable-gpl
  --enable-libmp3lame
  --enable-libopus
  # --- Enable specific encoders (one per line for clarity) ---
  --enable-encoder=libmp3lame
  --enable-encoder=aac
  --enable-encoder=libopus
  --enable-encoder=flac
  --enable-encoder=pcm_s16le
  # --- Enable specific decoders (one per line for clarity) ---
  --enable-decoder=mp3
  --enable-decoder=mp3*
  --enable-decoder=aac
  --enable-decoder=opus
  --enable-decoder=flac
  --enable-decoder=pcm_s16le
  # --- Enable specific demuxers (one per line for clarity) ---
  --enable-demuxer=mov
  --enable-demuxer=matroska
  --enable-demuxer=mp3
  --enable-demuxer=ogg
  --enable-demuxer=flac
  --enable-demuxer=wav
  --enable-demuxer=concat
  # --- Enable specific muxers (one per line for clarity) ---
  --enable-muxer=mp4
  --enable-muxer=mp3
  --enable-muxer=ogg
  --enable-muxer=flac
  --enable-muxer=wav
  # --- Enable specific parsers (one per line for clarity) ---
  --enable-parser=aac
  --enable-parser=flac
  --enable-parser=mpegaudio
  --enable-parser=opus
  # --- Enable REQUIRED audio filters (one per line for clarity) ---
  --enable-filter=aformat
  --enable-filter=highpass
  --enable-filter=afftdn
  --enable-filter=deesser
  --enable-filter=loudnorm
  --enable-filter=astats
  --enable-filter=ametadata
  --enable-filter=adynamicequalizer
  --enable-filter=alimiter
  --enable-filter=agate
  --enable-filter=equalizer
  --enable-filter=asoftclip
  --enable-filter=null
  --enable-filter=anull
  --enable-filter=abuffersink
  --enable-filter=abuffer
  --enable-filter=amix
  --enable-filter=aresample

  # --- Original Upstream Flags (modified for our build) ---
  --target-os=none              # disable target specific configs
  --arch=x86_32                 # use x86_32 arch
  --enable-cross-compile        # use cross compile configs
  --disable-asm                 # disable asm
  --disable-stripping           # disable stripping as it won't work
  # --disable-programs          # This is INTENTIONALLY commented out to build ffmpeg.c
  # --disable-doc               # This is already covered by --disable-all above
  --disable-debug               # disable debug mode
  --disable-runtime-cpudetect   # disable cpu detection
  --disable-autodetect          # disable env auto detect

  # assign toolchains and extra flags
  --nm=emnm
  --ar=emar
  --ranlib=emranlib
  --cc=emcc
  --cxx=em++
  --objcc=emcc
  --dep-cc=emcc
  --extra-cflags="$CFLAGS"
  --extra-cxxflags="$CXXFLAGS"

  # disable thread when FFMPEG_ST is NOT defined
  ${FFMPEG_ST:+ --disable-pthreads --disable-w32threads --disable-os2threads}
)

emconfigure ./configure "${CONF_FLAGS[@]}" "$@"
emmake make -j