#
# Makefile - The FFmpeg WASM Build System
#

# --- Build Flavors & Variables ---
all: dev
MT_FLAGS := -sUSE_PTHREADS -pthread
DEV_ARGS := --progress=plain
DEV_CFLAGS := --profiling
DEV_MT_CFLAGS := $(DEV_CFLAGS) $(MT_FLAGS)
PROD_CFLAGS := -O3 -msimd128
PROD_MT_CFLAGS := $(PROD_CFLAGS) $(MT_FLAGS)


# --- Core Build Logic ---

# FIX: This block adds the --builder flag ONLY when BUILDX_BUILDER is set
# by the GitHub Actions workflow. This ensures local builds are unaffected.
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
build-st:
	$(MAKE) build \
		FFMPEG_ST=yes

build-mt:
	$(MAKE) build \
		PKG_SUFFIX=-mt \
		FFMPEG_MT=yes

# --- Local Development Targets (No Regressions) ---
dev:
	$(MAKE) build-st EXTRA_CFLAGS="$(DEV_CFLAGS)" EXTRA_ARGS="$(DEV_ARGS)"

dev-mt:
	$(MAKE) build-mt EXTRA_CFLAGS="$(DEV_MT_CFLAGS)" EXTRA_ARGS="$(DEV_ARGS)"

prd:
	$(MAKE) build-st EXTRA_CFLAGS="$(PROD_CFLAGS)"

prd-mt:
	$(MAKE) build-mt EXTRA_CFLAGS="$(PROD_MT_CFLAGS)"


# --- Cleanup ---
clean:
	rm -rf ./packages/core$(PKG_SUFFIX)/dist