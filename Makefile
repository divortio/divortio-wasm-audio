#
# FILE: Makefile
#
# DESCRIPTION:
#   This Makefile orchestrates the entire build process for all ffmpeg.wasm packages.
#   It contains targets for cleaning, building, and testing the project.
#
# MODIFICATION:
#   We are adding two new production build targets: `prd-audio` and `prd-mt-audio`.
#   These targets are responsible for creating the custom, minimal audio-only builds.
#   They are designed to be drop-in additions that do not interfere with the original
#   `prd` and `prd-mt` targets.
#
####################################################################################################

# Find all build scripts.
BUILD_SCRIPTS := $(wildcard build/*.sh)

# Get the directory of the current Makefile.
ROOT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

# Define the path for the build cache.
BUILD_CACHE_DIR := $(ROOT_DIR)build-cache

# Define the Docker image name.
IMAGE_NAME := ffmpeg-wasm-builder

# Set the default goal to 'help'.
.DEFAULT_GOAL := help

# Phony targets are not real files.
.PHONY: help clean-cache build-image prd prd-mt prd-audio prd-mt-audio build-all test

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  help           Show this help message."
	@echo "  clean-cache    Remove the build cache."
	@echo "  build-image    Build the Docker image for building ffmpeg.wasm."
	@echo "  prd            Build single-thread version of ffmpeg.wasm."
	@echo "  prd-mt         Build multi-thread version of ffmpeg.wasm."
	@echo "  prd-audio      Build CUSTOM single-thread AUDIO-ONLY version of ffmpeg.wasm."
	@echo "  prd-mt-audio   Build CUSTOM multi-thread AUDIO-ONLY version of ffmpeg.wasm."
	@echo "  build-all      Build all versions of ffmpeg.wasm."
	@echo "  test           Run tests."

clean-cache:
	rm -rf $(BUILD_CACHE_DIR)-st $(BUILD_CACHE_DIR)-mt $(BUILD_CACHE_DIR)-st-audio $(BUILD_CACHE_DIR)-mt-audio

build-image:
	docker build -t $(IMAGE_NAME) .

#
# Original Production Build Target (Single-Threaded)
#
prd: FFMPEG_ST = 1
prd: EXTRA_ARGS =
prd:
	@echo "Building single-thread version of ffmpeg.wasm"
	@mkdir -p $(BUILD_CACHE_DIR)-st
	docker run --rm -v $(ROOT_DIR):/src -e FFMPEG_ST=$(FFMPEG_ST) $(IMAGE_NAME) \
		/src/build/ffmpeg.sh && \
		/src/build/ffmpeg-wasm.sh \
			-o ./packages/core/dist/ffmpeg-core.js \
			$(EXTRA_ARGS)

#
# Original Production Build Target (Multi-Threaded)
#
prd-mt: FFMPEG_MT = 1
prd-mt: EXTRA_ARGS =
prd-mt:
	@echo "Building multi-thread version of ffmpeg.wasm"
	@mkdir -p $(BUILD_CACHE_DIR)-mt
	docker run --rm -v $(ROOT_DIR):/src -e FFMPEG_MT=$(FFMPEG_MT) $(IMAGE_NAME) \
		/src/build/ffmpeg.sh && \
		/src/build/ffmpeg-wasm.sh \
			-o ./packages/core-mt/dist/ffmpeg-core.js \
			$(EXTRA_ARGS)

#
# NEW CUSTOM AUDIO BUILD TARGET (Single-Threaded)
# This is the new target for your custom audio-only ST build.
# - It sets the FFMPEG_ST environment variable.
# - It uses a separate build cache directory (`build-cache-st-audio`) to avoid conflicts.
# - CRITICAL: It calls your new `ffmpeg-audio.sh` and `ffmpeg-wasm-audio.sh` scripts.
#
prd-audio: FFMPEG_ST = 1
prd-audio: EXTRA_ARGS =
prd-audio:
	@echo "Building CUSTOM single-thread AUDIO-ONLY version of ffmpeg.wasm"
	@mkdir -p $(BUILD_CACHE_DIR)-st-audio
	docker run --rm -v $(ROOT_DIR):/src -e FFMPEG_ST=$(FFMPEG_ST) $(IMAGE_NAME) \
		/src/build/ffmpeg-audio.sh && \
		/src/build/ffmpeg-wasm-audio.sh \
			-o ./packages/core/dist/ffmpeg-core.js \
			$(EXTRA_ARGS)

#
# NEW CUSTOM AUDIO BUILD TARGET (Multi-Threaded)
# This is the new target for your custom audio-only MT build.
# - It sets the FFMPEG_MT environment variable.
# - It uses a separate build cache directory (`build-cache-mt-audio`) to avoid conflicts.
# - CRITICAL: It calls your new `ffmpeg-audio.sh` and `ffmpeg-wasm-audio.sh` scripts.
#
prd-mt-audio: FFMPEG_MT = 1
prd-mt-audio: EXTRA_ARGS =
prd-mt-audio:
	@echo "Building CUSTOM multi-thread AUDIO-ONLY version of ffmpeg.wasm"
	@mkdir -p $(BUILD_CACHE_DIR)-mt-audio
	docker run --rm -v $(ROOT_DIR):/src -e FFMPEG_MT=$(FFMPEG_MT) $(IMAGE_NAME) \
		/src/build/ffmpeg-audio.sh && \
		/src/build/ffmpeg-wasm-audio.sh \
			-o ./packages/core-mt/dist/ffmpeg-core.js \
			$(EXTRA_ARGS)

build-all: prd prd-mt

test:
	npm test