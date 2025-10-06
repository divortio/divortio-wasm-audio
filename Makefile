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
.PHONY: all clean build build-st build-mt dev dev-mt prd prd-mt

# The main build target. Now much simpler.
build:
	make clean PKG_SUFFIX="$(PKG_SUFFIX)"
	docker buildx build \
		--build-arg EXTRA_CFLAGS="$(EXTRA_CFLAGS)" \
		--build-arg EXTRA_LDFLAGS="$(EXTRA_LDFLAGS)" \
		--build-arg FFMPEG_MT="$(FFMPEG_MT)" \
		--build-arg FFMPEG_ST="$(FFMPEG_ST)" \
		-o ./packages/core$(PKG_SUFFIX) \
		.

# --- Build Targets ---
build-st:
	$(MAKE) build FFMPEG_ST=yes

build-mt:
	$(MAKE) build PKG_SUFFIX=-mt FFMPEG_MT=yes

# --- Local Development Targets ---
dev:
	$(MAKE) build-st EXTRA_CFLAGS="$(DEV_CFLAGS)"

dev-mt:
	$(MAKE) build-mt EXTRA_CFLAGS="$(DEV_MT_CFLAGS)"

prd:
	$(MAKE) build-st EXTRA_CFLAGS="$(PROD_CFLAGS)"

prd-mt:
	$(MAKE) build-mt EXTRA_CFLAGS="$(PROD_MT_CFLAGS)"

# --- Cleanup ---
clean:
	rm -rf ./packages/core$(PKG_SUFFIX)/dist