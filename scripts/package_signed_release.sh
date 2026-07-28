#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION_FILE="$ROOT_DIR/Config/version.env"
SPARKLE_CONFIG_FILE="$ROOT_DIR/Config/sparkle.env"
DIST_DIR="$ROOT_DIR/dist"
APP_PATH="$ROOT_DIR/甜喵物语.app"
BUILD_ARCHIVE="$ROOT_DIR/build/甜喵物语-clean-build.zip"
WORK_ROOT="${TMPDIR:-/tmp}/tianmiao-update-release.$$"

cleanup() {
  rm -rf "$WORK_ROOT"
}
trap cleanup EXIT

# shellcheck source=/dev/null
source "$VERSION_FILE"
# shellcheck source=/dev/null
source "$SPARKLE_CONFIG_FILE"

SPARKLE_ROOT="$("$ROOT_DIR/scripts/fetch_sparkle.sh")"
GENERATE_APPCAST="$SPARKLE_ROOT/bin/generate_appcast"
ARCHIVE_NAME="tianmiao-story-macos-v${APP_VERSION}.zip"
FINAL_ARCHIVE="$DIST_DIR/$ARCHIVE_NAME"
FEED_DIR="$DIST_DIR/sparkle-feed"
DOWNLOAD_PREFIX="https://github.com/Cyidid/tianmiao-story/releases/download/v${APP_VERSION}/"

mkdir -p "$WORK_ROOT" "$DIST_DIR" "$FEED_DIR"

release_kind="EdDSA-signed ad-hoc"
if [ -n "${DEVELOPER_ID_APPLICATION:-}" ] || [ -n "${NOTARY_PROFILE:-}" ]; then
  "$ROOT_DIR/scripts/verify_release_credentials.sh"
  CODE_SIGN_IDENTITY="$DEVELOPER_ID_APPLICATION" "$ROOT_DIR/scripts/build_app.sh"
  release_kind="Developer ID signed and notarized"
else
  echo "Developer ID is not configured; publishing an ad-hoc signed app with Sparkle EdDSA archive verification." >&2
  "$ROOT_DIR/scripts/build_app.sh"
fi

COPYFILE_DISABLE=1 ditto -x -k --norsrc "$BUILD_ARCHIVE" "$WORK_ROOT"
APP_PATH="$WORK_ROOT/甜喵物语.app"
codesign --verify --deep --strict "$APP_PATH"

if [ -n "${DEVELOPER_ID_APPLICATION:-}" ]; then
  SUBMISSION_ARCHIVE="$WORK_ROOT/notarization-$ARCHIVE_NAME"
  codesign -d --verbose=4 "$APP_PATH" 2>&1 | grep -Eq '^flags=.*runtime'
  COPYFILE_DISABLE=1 ditto -c -k --norsrc --keepParent "$APP_PATH" "$SUBMISSION_ARCHIVE"
  xcrun notarytool submit "$SUBMISSION_ARCHIVE" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait
  xcrun stapler staple "$APP_PATH"
  xcrun stapler validate "$APP_PATH"
  spctl --assess --type execute --verbose=2 "$APP_PATH"
fi

rm -f "$FINAL_ARCHIVE" "$FINAL_ARCHIVE.sha256"
COPYFILE_DISABLE=1 ditto -c -k --norsrc --keepParent "$APP_PATH" "$FINAL_ARCHIVE"
checksum=$(shasum -a 256 "$FINAL_ARCHIVE" | awk '{print $1}')
printf '%s\n' "$checksum" > "$FINAL_ARCHIVE.sha256"

rm -rf "$FEED_DIR/old_updates"
find "$FEED_DIR" -maxdepth 1 -type f \
  ! -name appcast.xml \
  -delete
COPYFILE_DISABLE=1 ditto --norsrc "$FINAL_ARCHIVE" "$FEED_DIR/$ARCHIVE_NAME"
cp "$ROOT_DIR/CHANGELOG.md" "$FEED_DIR/tianmiao-story-macos-v${APP_VERSION}.md"

"$GENERATE_APPCAST" \
  --account tianmiao-story \
  --download-url-prefix "$DOWNLOAD_PREFIX" \
  --embed-release-notes \
  --link "https://github.com/Cyidid/tianmiao-story" \
  --versions "$APP_BUILD" \
  --maximum-versions 3 \
  --maximum-deltas 0 \
  -o "$FEED_DIR/appcast.xml" \
  "$FEED_DIR"

test -s "$FEED_DIR/appcast.xml"
grep -Fq 'sparkle:edSignature=' "$FEED_DIR/appcast.xml"
grep -Fq "<sparkle:version>$APP_BUILD</sparkle:version>" "$FEED_DIR/appcast.xml"
grep -Fq "<sparkle:shortVersionString>$APP_VERSION</sparkle:shortVersionString>" "$FEED_DIR/appcast.xml"

printf 'Packaged %s update %s (%s)\nSHA256 %s\nAppcast %s\n' \
  "$release_kind" "$APP_VERSION" "$APP_BUILD" "$checksum" "$FEED_DIR/appcast.xml"
