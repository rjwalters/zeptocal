#!/bin/bash
# Build Zeptocal and assemble a menu-bar-only .app bundle.
set -euo pipefail
cd "$(dirname "$0")"

CONFIG=release
APP="Zeptocal.app"
BIN=".build/$CONFIG/Zeptocal"

echo "-> Building (${CONFIG})..."
swift build -c "$CONFIG"

echo "-> Assembling ${APP}..."
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN" "$APP/Contents/MacOS/Zeptocal"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Zeptocal</string>
    <key>CFBundleDisplayName</key><string>Zeptocal</string>
    <key>CFBundleIdentifier</key><string>com.robbwalters.zeptocal</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>CFBundleShortVersionString</key><string>0.1.0</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleExecutable</key><string>Zeptocal</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST

# Ad-hoc sign so macOS will launch it locally without Gatekeeper complaints.
codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || true

echo "Built ${APP}"
echo "  Run it with:  open ${APP}"
