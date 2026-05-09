#!/usr/bin/env bash
set -euo pipefail

ARCH="${1:?Usage: build-dmg.sh <arm64|x86_64|universal> <version>}"
VERSION="${2:?Usage: build-dmg.sh <arm64|x86_64|universal> <version>}"

case "$ARCH" in
  arm64)     ARCHS_VALUE="arm64" ;;
  x86_64)    ARCHS_VALUE="x86_64" ;;
  universal) ARCHS_VALUE="arm64 x86_64" ;;
  *)         echo "Unknown arch: $ARCH"; exit 1 ;;
esac

mkdir -p build/dmg

echo "==> Archiving for ${ARCH}..."
xcodebuild archive \
  -project glance.xcodeproj \
  -scheme glance \
  -configuration Release \
  -archivePath "build/glance-${ARCH}.xcarchive" \
  -destination 'generic/platform=macOS' \
  ARCHS="${ARCHS_VALUE}" \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  SKIP_INSTALL=NO

APP="build/glance-${ARCH}.xcarchive/Products/Applications/glance.app"
STAGING="build/dmg-staging-${ARCH}"
mkdir -p "$STAGING"
cp -R "$APP" "$STAGING/glance.app"

echo "==> Creating DMG..."
hdiutil create \
  -volname "glance" \
  -srcfolder "$STAGING" \
  -ov \
  -format UDZO \
  "build/dmg/glance-${VERSION}-${ARCH}.dmg"

echo "==> Done: build/dmg/glance-${VERSION}-${ARCH}.dmg"
