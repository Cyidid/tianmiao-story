#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PYTHON_BIN="${PYTHON_BIN:-python3}"
VERSION_FILE="$ROOT_DIR/Config/version.env"
APP_DIR="$ROOT_DIR/甜喵物语.app"
BUILD_ROOT="${TMPDIR:-/tmp}/tianmiao-build.$$"
BUILD_APP_DIR="$BUILD_ROOT/甜喵物语.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
SOURCE_FILE="$ROOT_DIR/Sources/TianMiao/main.swift"

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

"$PYTHON_BIN" "$ROOT_DIR/scripts/generate_rig_parts.py"
"$PYTHON_BIN" "$ROOT_DIR/scripts/verify_live2d_assets.py"

mkdir -p "$BUILD_ROOT" "$ROOT_DIR/build"

clean_app_metadata() {
  local target="$1"
  xattr -cr "$target" 2>/dev/null || true
  xattr -d com.apple.FinderInfo "$target" 2>/dev/null || true
  xattr -d 'com.apple.fileprovider.fpfs#P' "$target" 2>/dev/null || true
  xattr -rd com.apple.FinderInfo "$target" 2>/dev/null || true
  xattr -rd 'com.apple.fileprovider.fpfs#P' "$target" 2>/dev/null || true
  xattr -rd com.apple.ResourceFork "$target" 2>/dev/null || true
  xattr -rd com.apple.provenance "$target" 2>/dev/null || true
}

sign_and_verify() {
  local target="$1"
  local attempt
  for attempt in 1 2 3; do
    clean_app_metadata "$target"
    if codesign --force --deep --sign - "$target" >/dev/null 2>&1 &&
       codesign --verify --deep --strict "$target"; then
      return 0
    fi
    echo "Strict signing attempt $attempt failed for $target; retrying metadata cleanup." >&2
  done
  echo "Unable to strictly sign $target after 3 attempts." >&2
  return 1
}

APP_DIR="$BUILD_APP_DIR"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

swiftc "$SOURCE_FILE" \
  -target arm64-apple-macos13.0 \
  -framework Cocoa \
  -framework QuartzCore \
  -framework ServiceManagement \
  -framework UserNotifications \
  -o "$MACOS_DIR/tianmiao"

find "$RESOURCES_DIR" -type f -name '*.png' -delete
find "$RESOURCES_DIR" -type f -name '*.icns' -delete
for sprite in "$ROOT_DIR/Resources/"*.png; do
  COPYFILE_DISABLE=1 ditto --norsrc "$sprite" "$RESOURCES_DIR/$(basename "$sprite")"
done
COPYFILE_DISABLE=1 ditto --norsrc \
  "$ROOT_DIR/Resources/AppIcon.icns" \
  "$RESOURCES_DIR/AppIcon.icns"
if [ -d "$ROOT_DIR/Resources/Live2D" ]; then
  COPYFILE_DISABLE=1 ditto --norsrc \
    "$ROOT_DIR/Resources/Live2D" \
    "$RESOURCES_DIR/Live2D"
fi

cat > "$CONTENTS_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDisplayName</key>
  <string>甜喵物语</string>
  <key>CFBundleExecutable</key>
  <string>tianmiao</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleIdentifier</key>
  <string>com.jiujiu.catpet21</string>
  <key>CFBundleName</key>
  <string>甜喵物语</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$APP_VERSION</string>
  <key>CFBundleVersion</key>
  <string>$APP_BUILD</string>
  <key>LSUIElement</key>
  <true/>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSUserNotificationAlertStyle</key>
  <string>alert</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

sign_and_verify "$APP_DIR"

if [ -d "$ROOT_DIR/甜喵物语.app" ]; then
  mv "$ROOT_DIR/甜喵物语.app" "$ROOT_DIR/build/甜喵物语.app.previous.$$"
fi

# Moving the already-clean bundle avoids reintroducing Finder/file-provider
# metadata when the repository lives in a synced Documents directory.
mv "$APP_DIR" "$ROOT_DIR/甜喵物语.app"
APP_DIR="$ROOT_DIR/甜喵物语.app"
sign_and_verify "$APP_DIR"
echo "Built $APP_DIR"
rm -rf "$BUILD_ROOT"
