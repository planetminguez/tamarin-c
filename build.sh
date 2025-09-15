#!/usr/bin/env bash
# Simple build script for tamarin-c-main
# - Configures an out-of-source CMake build in ./build
# - Fetches Pico SDK automatically if PICO_SDK_PATH is not set
# - Builds with parallel jobs based on CPU count
# Usage:
#   ./build.sh           # configure (if needed) and build (Release)
#   ./build.sh clean     # remove ./build directory
# Environment:
#   BUILD_DIR   - build directory (default: build)
#   BUILD_TYPE  - CMAKE_BUILD_TYPE (default: Release)
#   JOBS        - parallel jobs (default: sysctl -n hw.ncpu)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

BUILD_DIR="${BUILD_DIR:-build}"
BUILD_TYPE="${BUILD_TYPE:-Release}"
JOBS="${JOBS:-$(sysctl -n hw.ncpu 2>/dev/null || echo 4)}"

if [[ "${1:-}" == "clean" ]]; then
  echo "Cleaning $BUILD_DIR" >&2
  rm -rf "$BUILD_DIR"
  exit 0
fi

# Decide whether to fetch Pico SDK from git
CMAKE_SDK_FLAG=""
if [[ -z "${PICO_SDK_PATH:-}" ]]; then
  echo "PICO_SDK_PATH not set; will fetch Pico SDK from git" >&2
  CMAKE_SDK_FLAG="-DPICO_SDK_FETCH_FROM_GIT=1"
fi

# Configure if needed
if [[ ! -f "$BUILD_DIR/CMakeCache.txt" ]]; then
  echo "Configuring CMake in $BUILD_DIR (BUILD_TYPE=$BUILD_TYPE)" >&2
  cmake -S . -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE="$BUILD_TYPE" $CMAKE_SDK_FLAG
else
  echo "CMake cache found in $BUILD_DIR; skipping configure" >&2
fi

# Build
echo "Building with $JOBS jobs" >&2
cmake --build "$BUILD_DIR" -j"$JOBS"

# Report artifact
UF2_PATH="$BUILD_DIR/tamarin_c.uf2"
if [[ -f "$UF2_PATH" ]]; then
  echo "Build OK: $UF2_PATH"
else
  echo "Build completed, but UF2 not found at $UF2_PATH" >&2
fi
