#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"
PKG="GymPlanBuilder"
APP_NAME="GymPlanBuilder"
BUNDLE_ID="com.thrivewood.gymplanbuilder"
VERSION="1.0"
BUILD_DIR=".build/app"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo "🔨 Building $PKG..."
swift build -c release 2>&1 | tail -1

echo "📦 Creating app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp ".build/arm64-apple-macosx/release/$PKG" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

cat > "$APP_BUNDLE/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>de</string>
    <key>CFBundleExecutable</key>
    <string>GymPlanBuilder</string>
    <key>CFBundleIdentifier</key>
    <string>com.thrivewood.gymplanbuilder</string>
    <key>CFBundleName</key>
    <string>GymPlanBuilder</string>
    <key>CFBundleDisplayName</key>
    <string>GymPlanBuilder</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticTermination</key>
    <true/>
    <key>NSSupportsSuddenTermination</key>
    <true/>
    <key>LSUIElement</key>
    <false/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST

cat > "$APP_BUNDLE/Contents/PkgInfo" <<< "APPL????"

echo "✅ App bundle created: $APP_BUNDLE"
echo "🚀 To run: open $APP_BUNDLE"
