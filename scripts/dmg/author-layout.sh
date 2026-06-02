#!/usr/bin/env bash
#
# One-time (dev-only) helper: bakes the DMG window layout — background image,
# window size, and icon positions — into a .DS_Store, captured to scripts/dmg/DS_Store.
# package.sh then reuses that committed .DS_Store so the release DMG is styled WITHOUT
# needing Finder/AppleScript at build time (which doesn't work on headless CI).
#
# Run this again only if you change background.png or the icon layout. It needs a GUI
# session and permission to control Finder (System Settings > Privacy & Security >
# Automation). Usage:  bash scripts/dmg/author-layout.sh [path-to-Horizon.app]
#
set -euo pipefail

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
BG="$REPO/scripts/dmg/background.png"
APP_SRC="${1:-/Applications/Horizon.app}"
VOL="Horizon"

[ -f "$BG" ] || { echo "✗ missing $BG"; exit 1; }
[ -d "$APP_SRC" ] || { echo "✗ missing app at $APP_SRC (pass one as arg 1)"; exit 1; }

hdiutil detach "/Volumes/$VOL" >/dev/null 2>&1 || true

STAGE="$(mktemp -d)"
mkdir "$STAGE/.background"
cp "$BG" "$STAGE/.background/background.png"
cp -R "$APP_SRC" "$STAGE/Horizon.app"
ln -s /Applications "$STAGE/Applications"

RW="$(mktemp -d)/rw.dmg"
hdiutil create -srcfolder "$STAGE" -volname "$VOL" -fs HFS+ -format UDRW -ov "$RW" >/dev/null
hdiutil attach "$RW" -noautoopen >/dev/null
sleep 1

osascript <<'OSA'
tell application "Finder"
  tell disk "Horizon"
    open
    delay 1
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {200, 120, 840, 610}
    set vo to the icon view options of container window
    set arrangement of vo to not arranged
    set icon size of vo to 96
    set background picture of vo to file ".background:background.png"
    set position of item "Horizon.app" of container window to {160, 180}
    set position of item "Applications" of container window to {480, 180}
    update without registering applications
    delay 1
    close
  end tell
end tell
OSA

sync; sleep 1
cp "/Volumes/$VOL/.DS_Store" "$REPO/scripts/dmg/DS_Store"
hdiutil detach "/Volumes/$VOL" >/dev/null 2>&1 || true
echo "✓ captured scripts/dmg/DS_Store ($(stat -f%z "$REPO/scripts/dmg/DS_Store") bytes)"
