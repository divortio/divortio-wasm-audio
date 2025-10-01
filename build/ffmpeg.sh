#!/bin/bash

set -euo pipefail

#
# divortio-wasm-audio: Custom Audio-Only Build Configuration
#
# We add our custom flags here. The script will combine these with the
# essential build flags below.
#
AUDIO_ONLY_FLAGS=(
  --disable-all
  --disable-avdevice
  --disable-swscale
  --disable-postproc
  --disable-avresample
  --disable-network

  # Enable essential components
  --enable-avcodec
  --enable-avformat
  --enable-avfilter
  --enable-swresample

  # Enable external libraries & licenses
  --enable-nonfree
  --enable-gpl
  --enable-libmp3lame
  --enable-libfdk_aac
  --enable-libopus

  # Enable specific encoders, decoders, demuxers, muxers, and parsers
  --enable-encoder=libmp3lame,libfdk_aac,libopus,flac,pcm_s16le
  --enable-decoder=mp3,aac,opus,flac,pcm_s16le
  --enable-demuxer=mov,matroska,mp3,ogg,flac,wav
  --enable-muxer=mp4,mp3,ogg,flac,wav
  --enable-parser=aac,flac,mpegaudio,opus

  # Enable REQUIRED filters
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
)

CONF_FLAGS=(
  # === Original Essential Flags ===
  --target-os=none              # disable target specific configs
  --arch=x86_32                 # use x86_32 arch
  --enable-cross-compile        # use cross compile configs
  --disable-asm                 # disable asm
  --disable-stripping           # disable stripping as it won't work
  --disable-programs            # disable ffmpeg, ffprobe and ffplay build
  --disable-doc                 # disable doc build
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
  #
  # === OPTIMIZATIONS: Added -msimd128 to enable WASM SIMD support ===
  #
  --extra-cflags="-msimd128 -s INITIAL_MEMORY=33554432 -O3 -flto"
  --extra-ldflags="-msimd128 -s INITIAL_MEMORY=33554432 -O3 -flto"

  # disable thread when FFMPEG_ST is defined
  ${FFMPEG_ST:+ --disable-pthreads --disable-w32threads --disable-os2threads}

  # === Injecting our Audio-Only Flags ===
  "${AUDIO_ONLY_FLAGS[@]}"
)

emconfigure ./configure "${CONF_FLAGS[@]}" "$@"
emmake make -j