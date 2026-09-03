#!/bin/bash
set -euo pipefail

APP_NAME="MacLatte"
BUILD_DIR=".build/release"
APP_BUNDLE="$APP_NAME.app"

echo "Building $APP_NAME (release)..."
swift build -c release

echo "Packaging $APP_BUNDLE..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
cp "Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

echo "Signing (ad-hoc)..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "Done. Built $APP_BUNDLE"
echo "Move it to /Applications, then launch it (or run: open $APP_BUNDLE)"
