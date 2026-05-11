#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [[ -t 1 ]]; then
  COLOR_BLUE=$'\033[1;34m'
  COLOR_YELLOW=$'\033[1;33m'
  COLOR_RED=$'\033[1;31m'
  COLOR_GREEN=$'\033[1;32m'
  COLOR_RESET=$'\033[0m'
else
  COLOR_BLUE=""
  COLOR_YELLOW=""
  COLOR_RED=""
  COLOR_GREEN=""
  COLOR_RESET=""
fi

banner() {
  printf "\n%s==>%s %s\n" "${COLOR_BLUE}" "${COLOR_RESET}" "$*"
}

success() {
  printf "%s%s%s\n" "${COLOR_GREEN}" "$*" "${COLOR_RESET}"
}

warn() {
  printf "%sWarning:%s %s\n" "${COLOR_YELLOW}" "${COLOR_RESET}" "$*" >&2
}

die() {
  printf "%sError:%s %s\n" "${COLOR_RED}" "${COLOR_RESET}" "$*" >&2
  exit 1
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

require_cmd() {
  local cmd
  for cmd in "$@"; do
    has_cmd "${cmd}" || die "Required command not found: ${cmd}"
  done
}

enter_repo_root() {
  cd "${REPO_ROOT}"
}

run_xcodebuild() {
  if has_cmd xcpretty; then
    set -o pipefail
    "$@" 2>&1 | xcpretty
  else
    warn "xcpretty is not installed. Falling back to raw xcodebuild output."
    "$@"
  fi
}
