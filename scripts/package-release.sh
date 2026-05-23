#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Reopen"
VERSION="${VERSION:-0.1.0}"
BUILD_DIR="$ROOT_DIR/build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
RELEASE_DIR="$BUILD_DIR/release"
DMG_ROOT="$BUILD_DIR/dmg-root"
DMG_PATH="$RELEASE_DIR/$APP_NAME-$VERSION.dmg"

mkdir -p "$RELEASE_DIR"

"$ROOT_DIR/scripts/build-app.sh" >/dev/null

rm -rf "$DMG_ROOT" "$DMG_PATH"
mkdir -p "$DMG_ROOT"
cp -R "$APP_DIR" "$DMG_ROOT/$APP_NAME.app"
ln -s /Applications "$DMG_ROOT/Applications"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_ROOT" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null

codesign --verify --deep --strict "$APP_DIR"

if [[ -n "${NOTARY_PROFILE:-}" ]]; then
  xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG_PATH"
else
  echo "Skipping notarization because NOTARY_PROFILE is not set."
fi

echo "$DMG_PATH"
