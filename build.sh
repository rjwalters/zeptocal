#!/bin/bash
# Build Zeptocal and assemble a menu-bar-only .app bundle.
set -euo pipefail
cd "$(dirname "$0")"

CONFIG=release
APP="Zeptocal.app"
DEST="/Applications/$APP"

INSTALL=0
for arg in "$@"; do
    case "$arg" in
        --install) INSTALL=1 ;;
        *) echo "usage: $0 [--install]" >&2; exit 2 ;;
    esac
done

BIN=".build/$CONFIG/Zeptocal"

echo "-> Building (${CONFIG})..."
swift build -c "$CONFIG"

echo "-> Assembling ${APP}..."
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Zeptocal"
cp Assets/Zeptocal.icns "$APP/Contents/Resources/Zeptocal.icns"

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
    <key>CFBundleIconFile</key><string>Zeptocal</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST

# Ad-hoc sign so macOS will launch it locally without Gatekeeper complaints.
codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || true

echo "Built ${APP}"

if [ "$INSTALL" -eq 0 ]; then
    echo "  Run it with:  open ${APP}"
    echo "  Or install:   $0 --install"
    exit 0
fi

echo "-> Installing to ${DEST}..."
if pkill -x Zeptocal 2>/dev/null; then
    # pkill only signals; wait (up to ~5s) so `open` launches the new bundle
    # instead of re-activating the exiting instance.
    for _ in $(seq 50); do
        pgrep -x Zeptocal >/dev/null || break
        sleep 0.1
    done
    if pgrep -x Zeptocal >/dev/null; then
        echo "Zeptocal did not quit; aborting install" >&2
        exit 1
    fi
fi
rm -rf "$DEST"
cp -R "$APP" "$DEST"
open "$DEST"
echo "Installed and relaunched ${DEST}"
