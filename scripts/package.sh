#!/usr/bin/env bash
#
# Builds Horizon (Release), ad-hoc signs it, and packages a distributable .dmg.
# Used both locally and by .github/workflows/release.yml. Uses only built-in tools —
# xcodebuild, codesign, hdiutil — no third-party dependencies.
#
# This script doubles as the packaging "smoke test": it fails loudly if the built
# app is missing, its signature doesn't verify, or the DMG won't mount.
#
set -euo pipefail

PROJECT="Horizon/Horizon.xcodeproj"
SCHEME="Horizon"
APP_NAME="Horizon"
BUILD_DIR="build"
DMG="${APP_NAME}.dmg"

echo "▶ Building ${SCHEME} (Release)…"
rm -rf "$BUILD_DIR" "$DMG"
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Release \
  -derivedDataPath "$BUILD_DIR" \
  ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO \
  build

APP="${BUILD_DIR}/Build/Products/Release/${APP_NAME}.app"

echo "▶ Ad-hoc signing ${APP_NAME}.app…"
codesign --force --sign - "$APP"

echo "▶ Smoke tests…"
[ -d "$APP" ] || { echo "✗ ${APP_NAME}.app not found at $APP"; exit 1; }
codesign --verify --strict "$APP"
[ -x "${APP}/Contents/MacOS/${APP_NAME}" ] || { echo "✗ executable missing"; exit 1; }
/usr/bin/file "${APP}/Contents/MacOS/${APP_NAME}" | grep -q "Mach-O" || { echo "✗ not a Mach-O binary"; exit 1; }
ARCHS_FOUND="$(lipo -archs "${APP}/Contents/MacOS/${APP_NAME}")"
echo "$ARCHS_FOUND" | grep -q "arm64"  || { echo "✗ missing arm64 slice"; exit 1; }
echo "$ARCHS_FOUND" | grep -q "x86_64" || { echo "✗ missing x86_64 slice (not universal)"; exit 1; }
echo "  ✓ app valid, ad-hoc signature verifies, universal ($ARCHS_FOUND)"

echo "▶ Building ${DMG}…"
STAGE="$(mktemp -d)"
cp -R "$APP" "${STAGE}/"
ln -s /Applications "${STAGE}/Applications"

# Style the DMG window: a background image (install steps + how to get past the one-time
# Gatekeeper "Apple could not verify" prompt) plus the pre-baked .DS_Store from
# scripts/dmg/author-layout.sh (window size, icon positions, background reference). This
# needs no Finder/AppleScript at build time, so it works on headless CI.
DMG_BG="scripts/dmg/background.png"
DMG_DS="scripts/dmg/DS_Store"
[ -f "$DMG_BG" ] || { echo "✗ DMG background not found at $DMG_BG"; exit 1; }
[ -f "$DMG_DS" ] || { echo "✗ DMG .DS_Store not found at $DMG_DS"; exit 1; }
mkdir "${STAGE}/.background"
cp "$DMG_BG" "${STAGE}/.background/background.png"
cp "$DMG_DS" "${STAGE}/.DS_Store"

hdiutil create -volname "${APP_NAME}" -srcfolder "${STAGE}" -ov -format UDZO "${DMG}" >/dev/null
rm -rf "${STAGE}"

echo "▶ Verifying ${DMG} mounts…"
hdiutil verify "${DMG}" >/dev/null
echo "  ✓ ${DMG} ($(du -h "${DMG}" | cut -f1)) ready for distribution"
