#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_FILE="$ROOT_DIR/Config/sparkle.env"
DEPENDENCIES_DIR="$ROOT_DIR/build/dependencies"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Missing Sparkle configuration: $CONFIG_FILE" >&2
  exit 1
fi

# shellcheck source=/dev/null
source "$CONFIG_FILE"
for variable in SPARKLE_VERSION SPARKLE_ARCHIVE_SHA256; do
  if [ -z "${!variable:-}" ]; then
    echo "Missing $variable in $CONFIG_FILE" >&2
    exit 1
  fi
done

SPARKLE_ROOT="$DEPENDENCIES_DIR/Sparkle-$SPARKLE_VERSION"
SPARKLE_FRAMEWORK="$SPARKLE_ROOT/Sparkle.framework"
if [ -d "$SPARKLE_FRAMEWORK" ]; then
  printf '%s\n' "$SPARKLE_ROOT"
  exit 0
fi

mkdir -p "$DEPENDENCIES_DIR"
ARCHIVE_PATH="$DEPENDENCIES_DIR/Sparkle-$SPARKLE_VERSION.tar.xz"
DOWNLOAD_URL="https://github.com/sparkle-project/Sparkle/releases/download/$SPARKLE_VERSION/Sparkle-$SPARKLE_VERSION.tar.xz"

if [ ! -f "$ARCHIVE_PATH" ]; then
  curl --location --fail --retry 3 --output "$ARCHIVE_PATH" "$DOWNLOAD_URL"
fi

actual_checksum=$(shasum -a 256 "$ARCHIVE_PATH" | awk '{print $1}')
if [ "$actual_checksum" != "$SPARKLE_ARCHIVE_SHA256" ]; then
  echo "Sparkle archive checksum mismatch." >&2
  exit 1
fi

mkdir -p "$SPARKLE_ROOT"
tar -xJf "$ARCHIVE_PATH" -C "$SPARKLE_ROOT"
if [ ! -d "$SPARKLE_FRAMEWORK" ] || [ ! -x "$SPARKLE_ROOT/bin/generate_appcast" ]; then
  echo "Sparkle archive is incomplete after extraction." >&2
  exit 1
fi

printf '%s\n' "$SPARKLE_ROOT"
