#
# FILE: Dockerfile
#
# DESCRIPTION:
#   This Dockerfile defines the build environment for compiling ffmpeg.wasm. It installs
#   all necessary dependencies, including the Emscripten SDK, build-essential tools,
#   and other required libraries.
#
# VERSION: 1.2
#
# CHANGE LOG:
#   - v1.2:
#     - FIXED BUG-003: Replaced the non-idempotent `adduser`/`addgroup` command with a
#       more robust script that checks for the existence of the user and group before
#       creation. This prevents build failures caused by changes in the base image.
#   - v1.1:
#     - FIXED BUG-002: Removed the final `RUN` commands that attempted to execute a
#       build within the Dockerfile itself.
#
####################################################################################################

FROM emscripten/emsdk:3.1.47

# 1. Install dependencies
RUN apt-get update && apt-get install -y \
    autoconf \
    automake \
    build-essential \
    ccache \
    cmake \
    git \
    libtool \
    ninja-build \
    pkg-config \
    python3 \
    texinfo \
    wget \
    yasm \
    zlib1g-dev

# 2. Install wasi-sdk
RUN wget https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-12/wasi-sdk-12.0-linux.tar.gz && \
    tar -zxf wasi-sdk-12.0-linux.tar.gz && \
    rm wasi-sdk-12.0-linux.tar.gz && \
    mv wasi-sdk-12.0 /opt/wasi-sdk
ENV PATH=/opt/wasi-sdk/bin:$PATH \
    CFLAGS="-I/opt/wasi-sdk/share/wasi-sysroot/include" \
    LDFLAGS="-L/opt/wasi-sdk/share/wasi-sysroot/lib/wasm32-wasi"

# 3. Create a non-root user
# This command is now idempotent. It checks if the group and user already exist before
# trying to create them, which prevents errors if the base image changes.
ENV UID=1000 GID=1000
RUN if ! getent group emscripten > /dev/null; then \
        addgroup --gid $GID emscripten; \
    fi && \
    if ! getent passwd emscripten > /dev/null; then \
        adduser --disabled-password --gecos "" --uid $UID --gid $GID emscripten; \
    fi
USER emscripten
WORKDIR /src