#!/usr/bin/env bash
# Flash script for tamarin-c-main
# - Waits for Pico's mass storage volume (default: /Volumes/RPI-RP2)
# - Copies the UF2 onto it when it appears
# - Optionally builds first if UF2 is missing
# Usage:
#   ./flash.sh                 # wait for RPI-RP2, copy build/tamarin_c.uf2
#   ./flash.sh --uf2 path.uf2  # specify a custom UF2
#   ./flash.sh --volume NAME   # specify a custom volume name
#   ./flash.sh --timeout SEC   # wait up to SEC seconds (0 = wait forever)
#   VOLUME=RPI-RP2 UF2=build/tamarin_c.uf2 TIMEOUT=120 ./flash.sh  # via env

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

UF2=${UF2:-build/tamarin_c.uf2}
VOLUME=${VOLUME:-RPI-RP2}
TIMEOUT=${TIMEOUT:-120}

# Simple arg parsing
while [[ $# -gt 0 ]]; do
  case "$1" in
    --uf2)
      UF2="$2"; shift 2;;
    --volume)
      VOLUME="$2"; shift 2;;
    --timeout)
      TIMEOUT="$2"; shift 2;;
    *)
      echo "Unknown argument: $1" >&2; exit 1;;
  esac
done

# Build if UF2 missing
if [[ ! -f "$UF2" ]]; then
  echo "UF2 not found at $UF2; attempting to build..." >&2
  if [[ -x ./build.sh ]]; then
    ./build.sh
  else
    echo "build.sh not found or not executable; aborting." >&2
    exit 1
  fi
fi

if [[ ! -f "$UF2" ]]; then
  echo "UF2 still not found at $UF2 after build; aborting." >&2
  exit 1
fi

TARGET="/Volumes/$VOLUME"

echo "Waiting for $TARGET to appear (TIMEOUT=${TIMEOUT}s; 0 = infinite)..."
start_ts=$(date +%s)
while [[ ! -d "$TARGET" ]]; do
  if [[ "$TIMEOUT" != "0" ]]; then
    now=$(date +%s)
    if (( now - start_ts >= TIMEOUT )); then
      echo "Timeout waiting for $TARGET" >&2
      exit 1
    fi
  fi
  sleep 0.5
  printf "."
done
printf "\n"
echo "Found $TARGET"

# Copy UF2
set -x
cp -v "$UF2" "$TARGET/"
set +x

# Wait for auto-reboot (volume unmount)
echo "Waiting for device to reboot (volume to unmount)..."
for i in {1..60}; do
  if [[ ! -d "$TARGET" ]]; then
    echo "Done: device rebooted."
    exit 0
  fi
  sleep 0.5
  printf "."
done
printf "\n"
echo "Note: Volume still mounted. The device may not have rebooted automatically."
exit 0
