#
# FILE: Dockerfile
#
# DESCRIPTION:
#   This Dockerfile defines the build environment for compiling ffmpeg.wasm. It installs
#   all necessary dependencies, including the Emscripten SDK, build-essential tools,
#   and other required libraries.
#
# VERSION: 1.1
#
# CHANGE LOG:
#   - v1.1:
#     - FIXED BUG-002: Removed the final `RUN` commands that attempted to execute a
#       build within the Dockerfile itself. This simplifies the image's responsibility
#       to only providing a build environment, allowing the Makefile to orchestrate
#       the actual compilation.
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
ENV UID=1000 GID=1000
RUN addgroup --gid $GID emscripten && \
    adduser --disabled-password --gecos "" --uid $UID --gid $GID emscripten
USER emscripten
WORKDIR /src

#
# The original Dockerfile had RUN commands here to build the project.
# These have been REMOVED as our Makefile now controls the build process.
# The Docker image's only job is to provide this environment.
#