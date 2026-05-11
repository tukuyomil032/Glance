#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

enter_repo_root

banner "Checking local development toolchain"

status=0

check_required() {
  local cmd="$1"
  if has_cmd "${cmd}"; then
    printf "  [ok] %s -> %s\n" "${cmd}" "$(command -v "${cmd}")"
  else
    printf "  [missing] %s\n" "${cmd}" >&2
    status=1
  fi
}

check_optional() {
  local cmd="$1"
  if has_cmd "${cmd}"; then
    printf "  [ok] %s -> %s\n" "${cmd}" "$(command -v "${cmd}")"
  else
    printf "  [optional] %s not found\n" "${cmd}"
  fi
}

check_required just
check_required xcodebuild
check_optional xcpretty
check_optional fd

if has_cmd xcodebuild; then
  printf "  [info] Xcode: %s\n" "$(xcodebuild -version | tr '\n' ' ' | sed 's/ $//')"
fi

if [[ -d build/DerivedData ]]; then
  printf "  [info] DerivedData: build/DerivedData\n"
fi

if [[ ${status} -ne 0 ]]; then
  die "Doctor checks failed. Install the missing required tools and try again."
fi

success "Doctor checks passed."
