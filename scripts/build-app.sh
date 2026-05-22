#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Reopen"
BUILD_DIR="$ROOT_DIR/build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"
TARGET="${TARGET:-arm64-apple-macosx13.0}"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

SOURCE_FILES="$(find "$ROOT_DIR/Reopen" -name '*.swift' -print | sort)"

swiftc \
  -sdk "$SDKROOT" \
  -target "$TARGET" \
  -parse-as-library \
  $SOURCE_FILES \
  -o "$MACOS_DIR/$APP_NAME"

cp "$ROOT_DIR/Reopen/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

ICONSET_DIR="$BUILD_DIR/AppIcon.iconset"
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

swift "$ROOT_DIR/scripts/generate-placeholder-icon.swift" "$ICONSET_DIR/icon_16x16.png" 16
swift "$ROOT_DIR/scripts/generate-placeholder-icon.swift" "$ICONSET_DIR/icon_16x16@2x.png" 32
swift "$ROOT_DIR/scripts/generate-placeholder-icon.swift" "$ICONSET_DIR/icon_32x32.png" 32
swift "$ROOT_DIR/scripts/generate-placeholder-icon.swift" "$ICONSET_DIR/icon_32x32@2x.png" 64
swift "$ROOT_DIR/scripts/generate-placeholder-icon.swift" "$ICONSET_DIR/icon_128x128.png" 128
swift "$ROOT_DIR/scripts/generate-placeholder-icon.swift" "$ICONSET_DIR/icon_128x128@2x.png" 256
swift "$ROOT_DIR/scripts/generate-placeholder-icon.swift" "$ICONSET_DIR/icon_256x256.png" 256
swift "$ROOT_DIR/scripts/generate-placeholder-icon.swift" "$ICONSET_DIR/icon_256x256@2x.png" 512
swift "$ROOT_DIR/scripts/generate-placeholder-icon.swift" "$ICONSET_DIR/icon_512x512.png" 512
swift "$ROOT_DIR/scripts/generate-placeholder-icon.swift" "$ICONSET_DIR/icon_512x512@2x.png" 1024

iconutil -c icns "$ICONSET_DIR" -o "$RESOURCES_DIR/AppIcon.icns"

if command -v codesign >/dev/null 2>&1; then
  codesign --force --sign - "$APP_DIR" >/dev/null
fi

echo "$APP_DIR"
