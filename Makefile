#
# Makefile - The FFmpeg WASM Build System
#

# --- Build Flavors & Variables ---

# Default target when running 'make'
all: dev

# Flags for multi-threaded builds
MT_FLAGS := -sUSE_PTHREADS -pthread

# Arguments for development builds (e.g., show plain progress)
DEV_ARGS := --progress=plain

# CFLAGS for different build types
DEV_CFLAGS := --profiling
DEV_MT_CFLAGS := $(DEV_CFLAGS) $(MT_FLAGS)
PROD_CFLAGS := -O3 -msimd128
PROD_MT_CFLAGS := $(PROD_CFLAGS) $(MT_FLAGS)


# --- Core Build Logic ---

# This is the critical fix. It checks if a BUILDX_BUILDER environment
# variable is set (which our GitHub Action will do) and adds the
# '--builder' flag to the Docker command. Otherwise, it does nothing,
# ensuring local builds still work as before.
ifdef BUILDX_BUILDER
BUILDER_ARG = --builder $(BUILDX_BUILDER)
else
BUILDER_ARG =
endif

# Common Docker build arguments
DOCKER_BUILD_ARGS = \
	--build-arg EXTRA_CFLAGS \
	--build-arg EXTRA_LDFLAGS \
	--build-arg FFMPEG_MT \
	--build-arg FFMPEG_ST \
	-o ./packages/core$(PKG_SUFFIX) \
	$(EXTRA_ARGS) \
	.

# This phony target prevents 'make' from confusing the 'build' command
# with a file named 'build'.
.PHONY: all clean build build-st build-mt dev dev-mt prd prd-mt

# The main build target that orchestrates the Docker build
build:
	@echo "--- Cleaning build directory ---"
	make clean PKG_SUFFIX="$(PKG_SUFFIX)"
	@echo "--- Starting Docker build ---"
	EXTRA_CFLAGS="$(EXTRA_CFLAGS)" \
	EXTRA_LDFLAGS="$(EXTRA_LDFLAGS)" \
	FFMPEG_ST="$(FFMPEG_ST)" \
	FFMPEG_MT="$(FFMPEG_MT)" \
		docker buildx build $(BUILDER_ARG) $(DOCKER_BUILD_ARGS)

# --- Build Targets ---

# Build Single-Threaded (ST) version
build-st:
	$(MAKE) build \
		FFMPEG_ST=yes

# Build Multi-Threaded (MT) version
build-mt:
	$(MAKE) build \
		PKG_SUFFIX=-mt \
		FFMPEG_MT=yes

# --- Local Development Targets (No Regressions) ---

# Default dev build: Single-threaded with profiling flags
dev:
	$(MAKE) build-st EXTRA_CFLAGS="$(DEV_CFLAGS)" EXTRA_ARGS="$(DEV_ARGS)"

# Multi-threaded dev build
dev-mt:
	$(MAKE) build-mt EXTRA_CFLAGS="$(DEV_MT_CFLAGS)" EXTRA_ARGS="$(DEV_ARGS)"

# Production build: Single-threaded with optimizations
prd:
	$(MAKE) build-st EXTRA_CFLAGS="$(PROD_CFLAGS)"

# Multi-threaded production build
prd-mt:
	$(MAKE) build-mt EXTRA_CFLAGS="$(PROD_MT_CFLAGS)"


# --- Cleanup ---

# Removes the build output directory
clean:
	rm -rf ./packages/core$(PKG_SUFFIX)/dist