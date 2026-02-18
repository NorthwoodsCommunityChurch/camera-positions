#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="Camera Positions"
SCHEME="CameraPositions"
BUILD_DIR="$SCRIPT_DIR/build"
APP_PATH="$BUILD_DIR/$APP_NAME.app"

echo "=== Building $APP_NAME ==="

# Generate Xcode project
echo "Generating Xcode project..."
xcodegen generate

# Build
echo "Building..."
xcodebuild -scheme "$SCHEME" \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    -quiet \
    build

# Find the built app
BUILT_APP=$(find "$BUILD_DIR/DerivedData/Build/Products/Release" -name "*.app" -maxdepth 1 | head -1)

if [ -z "$BUILT_APP" ]; then
    echo "ERROR: Build succeeded but app not found!"
    exit 1
fi

# Copy to build directory
echo "Copying to $APP_PATH..."
rm -rf "$APP_PATH"
cp -R "$BUILT_APP" "$APP_PATH"

# Clear extended attributes (OneDrive adds these, breaks code signing)
echo "Clearing extended attributes..."
xattr -cr "$APP_PATH"

# Copy Sparkle framework
SPARKLE_FRAMEWORK="$BUILD_DIR/DerivedData/Build/Products/Release/Sparkle.framework"
if [ -d "$SPARKLE_FRAMEWORK" ]; then
    echo "Bundling Sparkle framework..."
    APP_CONTENTS="$APP_PATH/Contents"
    mkdir -p "$APP_CONTENTS/Frameworks"
    xattr -cr "$SPARKLE_FRAMEWORK"
    cp -R "$SPARKLE_FRAMEWORK" "$APP_CONTENTS/Frameworks/"
    xattr -cr "$APP_CONTENTS/Frameworks/Sparkle.framework"

    # Sign nested Sparkle components inside-out
    codesign --force --sign - "$APP_CONTENTS/Frameworks/Sparkle.framework/Versions/B/XPCServices/Installer.xpc" 2>/dev/null || true
    codesign --force --sign - "$APP_CONTENTS/Frameworks/Sparkle.framework/Versions/B/XPCServices/Downloader.xpc" 2>/dev/null || true
    codesign --force --sign - "$APP_CONTENTS/Frameworks/Sparkle.framework/Versions/B/Updater.app" 2>/dev/null || true
    codesign --force --sign - "$APP_CONTENTS/Frameworks/Sparkle.framework/Versions/B/Autoupdate" 2>/dev/null || true
    codesign --force --sign - "$APP_CONTENTS/Frameworks/Sparkle.framework" 2>/dev/null || true
fi

# Ad-hoc code sign
echo "Signing..."
codesign --force --deep --sign - "$APP_PATH"

echo ""
echo "=== Build complete ==="
echo "App: $APP_PATH"
echo ""

# Kill any running instance and open
echo "Launching..."
pkill -x "CameraPositions" 2>/dev/null || true
sleep 1
open "$APP_PATH"
