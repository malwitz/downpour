#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h}"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT_DIR/Resources/Info.plist")"
OUTPUT_DIR="$ROOT_DIR/outputs"
DMG_PATH="$OUTPUT_DIR/Downpour-$VERSION-arm64.dmg"
STAGING_DIR="$(mktemp -d "$ROOT_DIR/work/Downpour-dmg.XXXXXX")"

"$ROOT_DIR/scripts/build-app.sh"
mkdir -p "$OUTPUT_DIR"

ditto "$ROOT_DIR/dist/Downpour.app" "$STAGING_DIR/Downpour.app"
ln -s /Applications "$STAGING_DIR/Applications"
cp "$ROOT_DIR/Resources/DMG-README.txt" "$STAGING_DIR/Read Me.txt"

hdiutil create \
  -volname "Downpour" \
  -srcfolder "$STAGING_DIR" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -ov \
  "$DMG_PATH"

echo "$DMG_PATH"
