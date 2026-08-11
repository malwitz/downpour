#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h}"
APP_DIR="$ROOT_DIR/dist/Downpour.app"
CONTENTS_DIR="$APP_DIR/Contents"
CACHE_DIR="$ROOT_DIR/work/build-cache"

cd "$ROOT_DIR"
mkdir -p "$CACHE_DIR/clang" "$CACHE_DIR/swiftpm" "$CACHE_DIR/config" "$CACHE_DIR/security"
CLANG_MODULE_CACHE_PATH="$CACHE_DIR/clang" swift build -c release --disable-sandbox \
  --cache-path "$CACHE_DIR/swiftpm" \
  --config-path "$CACHE_DIR/config" \
  --security-path "$CACHE_DIR/security"

rm -rf "$APP_DIR"
mkdir -p "$CONTENTS_DIR/MacOS" "$CONTENTS_DIR/Resources"
cp ".build/release/Downpour" "$CONTENTS_DIR/MacOS/Downpour"
cp "Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "Resources/DownpourIcon.icns" "$CONTENTS_DIR/Resources/DownpourIcon.icns"

codesign --force --deep --sign - "$APP_DIR"
echo "$APP_DIR"
