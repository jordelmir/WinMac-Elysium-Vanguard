#!/bin/bash
set -e

echo "🌌 ==================================================================== 🌌"
echo "⚡     WINMAC ELYSIUM VANGUARD - RELEASE APP BUNDLE COMPILER          ⚡"
echo "🌌 ==================================================================== 🌌"

PROJECT_DIR="$(pwd)"
BUILD_DIR="$PROJECT_DIR/build/Release"
APP_NAME="WinMac Elysium Vanguard.app"
APP_PATH="$BUILD_DIR/$APP_NAME"

cd "$PROJECT_DIR"

echo "🔨 Compiling release binaries via SwiftPM..."
swift build -c release --product elysium-app

echo "📦 Creating macOS .app bundle structure..."
rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

cp ".build/release/elysium-app" "$APP_PATH/Contents/MacOS/elysium-app"

# Copy SPM resource bundle if present
if [ -d ".build/release/ElysiumVanguard_ElysiumUI.bundle" ]; then
    cp -R ".build/release/ElysiumVanguard_ElysiumUI.bundle" "$APP_PATH/Contents/Resources/"
fi

if [ -f "Sources/ElysiumUI/Resources/AppIcon.icns" ]; then
    cp "Sources/ElysiumUI/Resources/AppIcon.icns" "$APP_PATH/Contents/Resources/AppIcon.icns"
    cp "Sources/ElysiumUI/Resources/AppIcon.icns" "$APP_PATH/Contents/Resources/AppIcon"
fi
if [ -f "Sources/ElysiumUI/Resources/elysium_logo.jpg" ]; then
    cp "Sources/ElysiumUI/Resources/elysium_logo.jpg" "$APP_PATH/Contents/Resources/elysium_logo.jpg"
fi

cat <<EOF > "$APP_PATH/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>elysium-app</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon.icns</string>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.elysium.vanguard</string>
    <key>CFBundleName</key>
    <string>WinMac Elysium Vanguard</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "APPL????" > "$APP_PATH/Contents/PkgInfo"

# Force macOS icon cache refresh
touch "$APP_PATH"
touch "$APP_PATH/Contents/Info.plist"

echo "✅ App bundle created successfully at:"
echo "   $APP_PATH"
