#!/usr/bin/env bash
set -euo pipefail

# Build script for tamarin-c (RP2040 / Pico SDK)
# This script reproduces the exact CMake commands used during the build.
## chmod it and run it special thanks to T.Roth

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${1:-$REPO_DIR/build}"

# Configure (fetches Pico SDK automatically if not present)
cmake -S "$REPO_DIR" -B "$BUILD_DIR" -G "Unix Makefiles" -DPICO_SDK_FETCH_FROM_GIT=ON

# Build
cmake --build "$BUILD_DIR" -j

echo "Build complete. Artifacts (e.g., tamarin_c.uf2) should be in: $BUILD_DIR"
