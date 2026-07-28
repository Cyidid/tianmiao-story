#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PYTHON_BIN="${PYTHON_BIN:-python3}"
VERSION_FILE="$ROOT_DIR/Config/version.env"
SPARKLE_CONFIG_FILE="$ROOT_DIR/Config/sparkle.env"
APP_DIR="$ROOT_DIR/甜喵物语.app"
BUILD_ROOT="${TMPDIR:-/tmp}/tianmiao-build.$$"
BUILD_APP_DIR="$BUILD_ROOT/甜喵物语.app"
BUILD_VERIFY_DIR="$BUILD_ROOT/verify"
BUILD_ARCHIVE="$ROOT_DIR/build/甜喵物语-clean-build.zip"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
SOURCE_FILES=("$ROOT_DIR/Sources/TianMiao/"*.swift)
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:--}"

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
if [ ! -f "$SPARKLE_CONFIG_FILE" ]; then
  echo "Missing Sparkle configuration: $SPARKLE_CONFIG_FILE" >&2
  exit 1
fi
# shellcheck source=/dev/null
source "$SPARKLE_CONFIG_FILE"
if [ -z "${SPARKLE_PUBLIC_ED_KEY:-}" ] || [ -z "${SPARKLE_FEED_URL:-}" ]; then
  echo "Sparkle public key and feed URL are required." >&2
  exit 1
fi
SPARKLE_ROOT="$("$ROOT_DIR/scripts/fetch_sparkle.sh")"
SPARKLE_FRAMEWORK="$SPARKLE_ROOT/Sparkle.framework"

"$PYTHON_BIN" "$ROOT_DIR/scripts/generate_rig_parts.py"

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
    if [ "$CODE_SIGN_IDENTITY" = "-" ]; then
      codesign_args=(--force --deep --sign -)
    else
      codesign_args=(--force --deep --options runtime --timestamp --sign "$CODE_SIGN_IDENTITY")
    fi
    if codesign "${codesign_args[@]}" "$target" >/dev/null 2>&1 &&
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
FRAMEWORKS_DIR="$CONTENTS_DIR/Frameworks"

mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$FRAMEWORKS_DIR"

swiftc "${SOURCE_FILES[@]}" \
  -target arm64-apple-macos13.0 \
  -F "$SPARKLE_ROOT" \
  -framework Cocoa \
  -framework QuartzCore \
  -framework ServiceManagement \
  -framework Sparkle \
  -framework UserNotifications \
  -Xlinker -rpath \
  -Xlinker @executable_path/../Frameworks \
  -o "$MACOS_DIR/tianmiao"

find "$RESOURCES_DIR" -type f -name '*.png' -delete
find "$RESOURCES_DIR" -type f -name '*.icns' -delete
for sprite in "$ROOT_DIR/Resources/"*.png; do
  COPYFILE_DISABLE=1 cp "$sprite" "$RESOURCES_DIR/$(basename "$sprite")"
done
if [ -d "$ROOT_DIR/Resources/Poses" ]; then
  COPYFILE_DISABLE=1 cp -R "$ROOT_DIR/Resources/Poses" "$RESOURCES_DIR/Poses"
fi
COPYFILE_DISABLE=1 cp "$ROOT_DIR/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"

# Synced folders may attach FinderInfo/file-provider attributes to nested
# Sparkle bundles. A metadata-free tar stream preserves symlinks and executable
# modes while preventing those attributes from invalidating strict codesign.
COPYFILE_DISABLE=1 tar -C "$SPARKLE_ROOT" -cf - Sparkle.framework |
  COPYFILE_DISABLE=1 tar -C "$FRAMEWORKS_DIR" -xf -

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
  <key>SUEnableAutomaticChecks</key>
  <true/>
  <key>SUScheduledCheckInterval</key>
  <integer>86400</integer>
  <key>SUFeedURL</key>
  <string>$SPARKLE_FEED_URL</string>
  <key>SUPublicEDKey</key>
  <string>$SPARKLE_PUBLIC_ED_KEY</string>
</dict>
</plist>
PLIST

sign_and_verify "$APP_DIR"

rm -f "$BUILD_ARCHIVE"
COPYFILE_DISABLE=1 ditto -c -k --norsrc --keepParent "$APP_DIR" "$BUILD_ARCHIVE"
mkdir -p "$BUILD_VERIFY_DIR"
COPYFILE_DISABLE=1 ditto -x -k --norsrc "$BUILD_ARCHIVE" "$BUILD_VERIFY_DIR"
codesign --verify --deep --strict "$BUILD_VERIFY_DIR/甜喵物语.app"

if [ -d "$ROOT_DIR/甜喵物语.app" ]; then
  mv "$ROOT_DIR/甜喵物语.app" "$ROOT_DIR/build/甜喵物语.app.previous.$$"
fi

# This copy is a launch convenience only. Synced Documents directories may
# immediately attach Finder/file-provider metadata, so release verification
# always uses BUILD_ARCHIVE instead.
COPYFILE_DISABLE=1 cp -R "$APP_DIR" "$ROOT_DIR/甜喵物语.app"
echo "Built $ROOT_DIR/甜喵物语.app"
echo "Verified clean build archive $BUILD_ARCHIVE"
rm -rf "$BUILD_ROOT"
