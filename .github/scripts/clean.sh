#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

enter_repo_root

banner "Cleaning local build artifacts"

rm -rf build

success "Removed build/"
