#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

enter_repo_root
require_cmd open

APP_PATH="build/DerivedData/Build/Products/Debug/glance.app"

banner "Launching built app"

if [[ ! -d "${APP_PATH}" ]]; then
  die "App bundle not found at ${APP_PATH}. Run 'just build' first."
fi

open "${APP_PATH}"

success "Opened ${APP_PATH}"
