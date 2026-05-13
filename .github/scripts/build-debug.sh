#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

enter_repo_root
require_cmd xcodebuild

banner "Building glance (Debug)"

run_xcodebuild xcodebuild \
  -project glance.xcodeproj \
  -scheme glance \
  -configuration Debug \
  -derivedDataPath build/DerivedData \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  build | bundle exec xcpretty -c

success "Debug build finished: build/DerivedData/Build/Products/Debug/glance.app"
