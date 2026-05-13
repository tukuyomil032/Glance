#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

ARCH="${1:?Usage: build-dmg.sh <arm64|x86_64|universal> <version>}"
VERSION="${2:?Usage: build-dmg.sh <arm64|x86_64|universal> <version>}"

enter_repo_root
require_cmd xcodebuild codesign spctl hdiutil cp mkdir

case "$ARCH" in
  arm64)     ARCHS_VALUE="arm64" ;;
  x86_64)    ARCHS_VALUE="x86_64" ;;
  universal) ARCHS_VALUE="arm64 x86_64" ;;
  *)         die "Unknown arch: ${ARCH}. Expected arm64, x86_64, or universal." ;;
esac

mkdir -p build/dmg

banner "Archiving release build for ${ARCH}"
run_xcodebuild xcodebuild archive \
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
  SKIP_INSTALL=NO | bundle exec xcpretty -c

APP="build/glance-${ARCH}.xcarchive/Products/Applications/glance.app"
STAGING="build/dmg-staging-${ARCH}"

[[ -d "${APP}" ]] || die "Expected app bundle not found: ${APP}"

rm -rf "$STAGING"
mkdir -p "$STAGING"
cp -R "$APP" "$STAGING/glance.app"

banner "Re-signing staged app bundle"
codesign --force --deep --sign - --timestamp=none "$STAGING/glance.app"

banner "Verifying staged app bundle"
codesign --verify --deep --strict --verbose=4 "$STAGING/glance.app"
if ! spctl --assess --type execute --verbose=4 "$STAGING/glance.app"; then
  warn "spctl rejected the ad-hoc signed app bundle. Continuing because local DMG builds are unsigned by design."
fi

banner "Creating DMG"
hdiutil create \
  -volname "glance" \
  -srcfolder "$STAGING" \
  -ov \
  -format UDZO \
  "build/dmg/glance-${VERSION}-${ARCH}.dmg"

success "Done: build/dmg/glance-${VERSION}-${ARCH}.dmg"
