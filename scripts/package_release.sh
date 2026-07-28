#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION_FILE="$ROOT_DIR/Config/version.env"
DIST_DIR="$ROOT_DIR/dist"
VERIFY_ROOT="${TMPDIR:-/tmp}/tianmiao-release-verify.$$"

if [ ! -f "$VERSION_FILE" ]; then
  echo "Missing version configuration: $VERSION_FILE" >&2
  exit 1
fi

# shellcheck source=/dev/null
source "$VERSION_FILE"
if [[ ! "${APP_VERSION:-}" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
  echo "APP_VERSION must be a numeric dotted version." >&2
  exit 1
fi
if [[ ! "${APP_BUILD:-}" =~ ^[1-9][0-9]*$ ]]; then
  echo "APP_BUILD must be a positive integer." >&2
  exit 1
fi

ARCHIVE_NAME="tianmiao-story-macos-v${APP_VERSION}.zip"
ARCHIVE_PATH="$DIST_DIR/$ARCHIVE_NAME"
APP_PATH="$ROOT_DIR/甜喵物语.app"
BUILD_ARCHIVE="$ROOT_DIR/build/甜喵物语-clean-build.zip"

cleanup() {
  rm -rf "$VERIFY_ROOT"
}
trap cleanup EXIT

"$ROOT_DIR/scripts/build_app.sh"
mkdir -p "$DIST_DIR" "$VERIFY_ROOT"
rm -f "$ARCHIVE_PATH"

COPYFILE_DISABLE=1 ditto -x -k --norsrc "$BUILD_ARCHIVE" "$VERIFY_ROOT"

VERIFIED_APP="$VERIFY_ROOT/甜喵物语.app"
codesign --verify --deep --strict "$VERIFIED_APP"

verified_version=$(/usr/libexec/PlistBuddy \
  -c "Print :CFBundleShortVersionString" \
  "$VERIFIED_APP/Contents/Info.plist")
verified_build=$(/usr/libexec/PlistBuddy \
  -c "Print :CFBundleVersion" \
  "$VERIFIED_APP/Contents/Info.plist")

if [ "$verified_version" != "$APP_VERSION" ] || [ "$verified_build" != "$APP_BUILD" ]; then
  echo "Packaged version mismatch: expected $APP_VERSION ($APP_BUILD), got $verified_version ($verified_build)." >&2
  exit 1
fi

COPYFILE_DISABLE=1 ditto -c -k --norsrc --keepParent "$VERIFIED_APP" "$ARCHIVE_PATH"
checksum=$(shasum -a 256 "$ARCHIVE_PATH" | awk '{print $1}')
printf 'Packaged %s (%s)\nSHA256 %s\n' "$APP_VERSION" "$APP_BUILD" "$checksum"
printf '%s\n' "$checksum" > "$ARCHIVE_PATH.sha256"
