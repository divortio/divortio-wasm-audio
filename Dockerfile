#
# FILE: Dockerfile
#
# DESCRIPTION:
#   This Dockerfile is a minimally modified version of the original, designed to
#   create a custom, audio-only build of ffmpeg.wasm. All modifications are
#   done by commenting out unnecessary lines and adding the required audio
#   configuration, preserving the original structure for clarity and maintenance.
#
# VERSION: 7.0
#
# CHANGE LOG:
#   - v7.0:
#     - CORRECTED: Added the final `exporter` stage to ensure build artifacts
#       can be extracted, as per user direction.
#     - All other changes follow the user-approved methodology of commenting out
#       and adding lines to the original file.
#
####################################################################################################

# syntax=docker/dockerfile-upstream:master-labs

# Base emsdk image with environment variables.
FROM emscripten/emsdk:3.1.40 AS emsdk-base
ARG EXTRA_CFLAGS
ARG EXTRA_LDFLAGS
ARG FFMPEG_ST
ARG FFMPEG_MT
ENV INSTALL_DIR=/opt
# We cannot upgrade to n6.0 as ffmpeg bin only supports multithread at the moment.
ENV FFMPEG_VERSION=n5.1.4
ENV CFLAGS="-I$INSTALL_DIR/include $CFLAGS $EXTRA_CFLAGS"
ENV CXXFLAGS="$CFLAGS"
ENV LDFLAGS="-L$INSTALL_DIR/lib $LDFLAGS $CFLAGS $EXTRA_LDFLAGS"
ENV EM_PKG_CONFIG_PATH=$EM_PKG_CONFIG_PATH:$INSTALL_DIR/lib/pkgconfig:/emsdk/upstream/emscripten/system/lib/pkgconfig
ENV EM_TOOLCHAIN_FILE=$EMSDK/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake
ENV PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$EM_PKG_CONFIG_PATH
ENV FFMPEG_ST=$FFMPEG_ST
ENV FFMPEG_MT=$FFMPEG_MT
RUN apt-get update && \
      apt-get install -y pkg-config autoconf automake libtool ragel

# # Build x264
# FROM emsdk-base AS x264-builder
# ENV X264_BRANCH=4-cores
# ADD https://github.com/ffmpegwasm/x264.git#$X264_BRANCH /src
# COPY build/x264.sh /src/build.sh
# RUN bash -x /src/build.sh

# # Build x265
# FROM emsdk-base AS x265-builder
# ENV X265_TAG=3.5
# ADD https://github.com/videolan/x265/archive/refs/tags/$X265_TAG.tar.gz /src.tar.gz
# RUN tar -zxf /src.tar.gz && \
#     rm /src.tar.gz && \
#     mv x265_$X265_TAG /src
# COPY build/x265.sh /src/build.sh
# RUN bash -x /src/build.sh

# # Build libvpx
# FROM emsdk-base AS libvpx-builder
# ENV LIBVPX_VERSION=1.12.0
# ADD https://github.com/webmproject/libvpx/archive/refs/tags/v$LIBVPX_VERSION.tar.gz /src.tar.gz
# RUN tar -zxf /src.tar.gz && \
#     rm /src.tar.gz && \
#     mv libvpx-$LIBVPX_VERSION /src
# COPY build/libvpx.sh /src/build.sh
# RUN bash -x /src/build.sh

# Build lame
FROM emsdk-base AS lame-builder
ENV LAME_VERSION=3.100
ADD https://sourceforge.net/projects/lame/files/lame/$LAME_VERSION/lame-$LAME_VERSION.tar.gz /src.tar.gz
RUN tar -zxf /src.tar.gz && \
    rm /src.tar.gz && \
    mv lame-$LAME_VERSION /src
COPY build/lame.sh /src/build.sh
RUN bash -x /src/build.sh

# Build ogg
FROM emsdk-base AS ogg-builder
ENV OGG_VERSION=1.3.5
ADD https://downloads.xiph.org/releases/ogg/libogg-$OGG_VERSION.tar.gz /src.tar.gz
RUN tar -zxf /src.tar.gz && \
    rm /src.tar.gz && \
    mv libogg-$OGG_VERSION /src
COPY build/ogg.sh /src/build.sh
RUN bash -x /src/build.sh

# Build vorbis
FROM ogg-builder AS vorbis-builder
ENV VORBIS_VERSION=1.3.7
ADD https://downloads.xiph.org/releases/vorbis/libvorbis-$VORBIS_VERSION.tar.gz /src.tar.gz
RUN tar -zxf /src.tar.gz && \
    rm /src.tar.gz && \
    mv libvorbis-$VORBIS_VERSION /src
COPY build/vorbis.sh /src/build.sh
RUN bash -x /src/build.sh

# # Build theora
# FROM vorbis-builder AS theora-builder
# ENV THEORA_VERSION=1.1.1
# ADD https://downloads.xiph.org/releases/theora/libtheora-$THEORA_VERSION.tar.gz /src.tar.gz
# RUN tar -zxf /src.tar.gz && \
#     rm /src.tar.gz && \
#     mv libtheora-$THEORA_VERSION /src
# COPY build/theora.sh /src/build.sh
# RUN bash -x /src/build.sh

# Build opus
FROM emsdk-base AS opus-builder
ENV OPUS_VERSION=1.3.1
ADD https://archive.mozilla.org/pub/opus/opus-$OPUS_VERSION.tar.gz /src.tar.gz
RUN tar -zxf /src.tar.gz && \
    rm /src.tar.gz && \
    mv opus-$OPUS_VERSION /src
COPY build/opus.sh /src/build.sh
RUN bash -x /src/build.sh

# Build zlib
FROM emsdk-base AS zlib-builder
ENV ZLIB_VERSION=1.2.13
ADD https://www.zlib.net/zlib-$ZLIB_VERSION.tar.gz /src.tar.gz
RUN tar -zxf /src.tar.gz && \
    rm /src.tar.gz && \
    mv zlib-$ZLIB_VERSION /src
COPY build/zlib.sh /src/build.sh
RUN bash -x /src/build.sh

# # Build libwebp
# FROM zlib-builder AS libwebp-builder
# ENV LIBWEBP_VERSION=1.3.0
# ADD https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-$LIBWEBP_VERSION.tar.gz /src.tar.gz
# RUN tar -zxf /src.tar.gz && \
#     rm /src.tar.gz && \
#     mv libwebp-$LIBWEBP_VERSION /src
# COPY build/libwebp.sh /src/build.sh
# RUN bash -x /src/build.sh

# # Build freetype2
# FROM zlib-builder AS freetype2-builder
# ENV FREETYPE2_VERSION=2.13.0
# ADD https://download.savannah.gnu.org/releases/freetype/freetype-$FREETYPE2_VERSION.tar.gz /src.tar.gz
# RUN tar -zxf /src.tar.gz && \
#     rm /src.tar.gz && \
#     mv freetype-$FREETYPE2_VERSION /src
# COPY build/freetype2.sh /src/build.sh
# RUN bash -x /src/build.sh

# # Build fribidi
# FROM emsdk-base AS fribidi-builder
# ENV FRIBIDI_VERSION=1.0.12
# ADD https://github.com/fribidi/fribidi/releases/download/v$FRIBIDI_VERSION/fribidi-$FRIBIDI_VERSION.tar.xz /src.tar.xz
# RUN apt-get update && apt-get install -y xz-utils && \
#     tar -xf /src.tar.xz && \
#     rm /src.tar.xz && \
#     mv fribidi-$FRIBIDI_VERSION /src
# COPY build/fribidi.sh /src/build.sh
# RUN bash -x /src/build.sh

# # Build harfbuzz
# FROM freetype2-builder AS harfbuzz-builder
# COPY --from=fribidi-builder $INSTALL_DIR $INSTALL_DIR
# ENV HARFBUZZ_VERSION=7.2.0
# ADD https://github.com/harfbuzz/harfbuzz/releases/download/$HARFBUZZ_VERSION/harfbuzz-$HARFBUZZ_VERSION.tar.xz /src.tar.xz
# RUN apt-get update && apt-get install -y xz-utils && \
#     tar -xf /src.tar.xz && \
#     rm /src.tar.xz && \
#     mv harfbuzz-$HARFBUZZ_VERSION /src
# COPY build/harfbuzz.sh /src/build.sh
# RUN bash -x /src/build.sh

# # Build libass
# FROM harfbuzz-builder AS libass-builder
# ENV LIBASS_VERSION=0.17.1
# ADD https://github.com/libass/libass/releases/download/$LIBASS_VERSION/libass-$LIBASS_VERSION.tar.gz /src.tar.gz
# RUN tar -zxf /src.tar.gz && \
#     rm /src.tar.gz && \
#     mv libass-$LIBASS_VERSION /src
# COPY build/libass.sh /src/build.sh
# RUN bash -x /src/build.sh

# # Build zimg
# FROM emsdk-base AS zimg-builder
# ENV ZIMG_VERSION=3.0.4
# ADD https://github.com/sekrit-twc/zimg/archive/refs/tags/release-$ZIMG_VERSION.tar.gz /src.tar.gz
# RUN tar -zxf /src.tar.gz && \
#     rm /src.tar.gz && \
#     mv zimg-release-$ZIMG_VERSION /src
# COPY build/zimg.sh /src/build.sh
# RUN bash -x /src/build.sh

# Base image with UID/GID and ffmpeg source code.
FROM emsdk-base AS ffmpeg-base
# ENV UID=1000 GID=1000
# RUN addgroup --gid $GID emscripten || true && \
#     adduser --disabled-password --gecos "" --uid $UID --gid $GID emscripten
# USER emscripten
WORKDIR /src
ADD https://github.com/FFmpeg/FFmpeg/archive/refs/tags/$FFMPEG_VERSION.tar.gz /src.tar.gz
RUN tar -zxf /src.tar.gz && \
    rm /src.tar.gz && \
    mv FFmpeg-$FFMPEG_VERSION ffmpeg
# COPY --from=x264-builder $INSTALL_DIR $INSTALL_DIR
# COPY --from=x265-builder $INSTALL_DIR $INSTALL_DIR
# COPY --from=libvpx-builder $INSTALL_DIR $INSTALL_DIR
COPY --from=lame-builder $INSTALL_DIR $INSTALL_DIR
# COPY --from=theora-builder $INSTALL_DIR $INSTALL_DIR
COPY --from=opus-builder $INSTALL_DIR $INSTALL_DIR
# COPY --from=libwebp-builder $INSTALL_DIR $INSTALL_DIR
# COPY --from=libass-builder $INSTALL_DIR $INSTALL_DIR
# COPY --from=zimg-builder $INSTALL_DIR $INSTALL_DIR

# Build ffmpeg
FROM ffmpeg-base AS ffmpeg-builder
COPY build/ffmpeg.sh /src/build.sh
# NEW: Custom audio-only build configuration
RUN bash -x /src/build.sh \
      --disable-all \
      --disable-avdevice \
      --disable-swscale \
      --disable-postproc \
      --disable-network \
      --disable-doc \
      --enable-avcodec \
      --enable-avformat \
      --enable-avfilter \
      --enable-swresample \
      --enable-gpl \
      --enable-libmp3lame \
      --enable-libopus \
      --enable-encoder=libmp3lame,aac,libopus,flac,pcm_s16le \
      --enable-decoder=mp3,aac,opus,flac,pcm_s16le \
      --enable-demuxer=mov,matroska,mp3,ogg,flac,wav \
      --enable-muxer=mp4,mp3,ogg,flac,wav \
      --enable-parser=aac,flac,mpegaudio,opus \
      --enable-filter=aformat,highpass,afftdn,deesser,loudnorm,astats,ametadata,adynamicequalizer,alimiter,agate,equalizer,asoftclip
# OLD: Original build configuration is now commented out
# RUN bash -x /src/build.sh \
#       --enable-gpl \
#       --enable-libx264 \
#       --enable-libx265 \
#       --enable-libvpx \
#       --enable-libmp3lame \
#       --enable-libtheora \
#       --enable-libvorbis \
#       --enable-libopus \
#       --enable-zlib \
#       --enable-libwebp \
#       --enable-libfreetype \
#       --enable-libfribidi \
#       --enable-libass \
#       --enable-libzimg

# Build ffmpeg.wasm
FROM ffmpeg-builder AS ffmpeg-wasm-builder
COPY src/bind /src/src/bind
COPY src/fftools /src/src/fftools
COPY build/ffmpeg-wasm.sh build.sh
# NEW: Custom audio-only library linker flags
ENV FFMPEG_LIBS \
      -lmp3lame \
      -lopus \
      -lvorbis \
      -logg
# OLD: Original linker flags are now commented out
# # libraries to link
# ENV FFMPEG_LIBS \
#       -lx264 \
#       -lx265 \
#       -lvpx \
#       -lmp3lame \
#       -logg \
#       -ltheora \
#       -lvorbis \
#       -lvorbisenc \
#       -lvorbisfile \
#       -lopus \
#       -lz \
#       -lwebpmux \
#       -lwebp \
#       -lsharpyuv \
#       -lfreetype \
#       -lfribidi \
#       -lass \
#       -lharfbuzz \
#       -lzimg
RUN mkdir -p /src/dist/umd && bash -x /src/build.sh \
      ${FFMPEG_LIBS} \
      -o dist/umd/ffmpeg-core.js
RUN mkdir -p /src/dist/esm && bash -x /src/build.sh \
      ${FFMPEG_LIBS} \
      -o dist/esm/ffmpeg-core.js

# Export ffmpeg-core.wasm to dist/, use `docker buildx build -o . .` to get assets
FROM scratch AS exportor
COPY --from=ffmpeg-wasm-builder /src/dist /dist