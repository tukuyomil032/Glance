set shell := ["bash", "-euo", "pipefail", "-c"]

default: help

help_summary := "Show available development and release commands"
build_summary := "Build the app in Debug mode"
test_summary := "Run glanceTests in Debug mode"
run_summary := "Launch the built Debug app"
clean_summary := "Remove local build artifacts"
doctor_summary := "Check required local tools and environment"
dmg_summary := "Build a release DMG (arch: arm64|x86_64|universal, version: e.g. 1.03)"
ci_summary := "Run local CI flow: doctor -> build -> test"

# Show available development and release commands
help recipe="":
  #!/usr/bin/env bash
  set -euo pipefail
  show_list() {
    local output_fd="${1:-1}"
    printf '\n%s\n\n' 'glance development commands' >&"${output_fd}"
    printf '%-30s %s\n' '  just help' '{{help_summary}}' >&"${output_fd}"
    printf '%-30s %s\n' '  just build' '{{build_summary}}' >&"${output_fd}"
    printf '%-30s %s\n' '  just test' '{{test_summary}}' >&"${output_fd}"
    printf '%-30s %s\n' '  just run' '{{run_summary}}' >&"${output_fd}"
    printf '%-30s %s\n' '  just clean' '{{clean_summary}}' >&"${output_fd}"
    printf '%-30s %s\n' '  just doctor' '{{doctor_summary}}' >&"${output_fd}"
    printf '%-30s %s\n' '  just dmg <arch> <version>' '{{dmg_summary}}' >&"${output_fd}"
    printf '%-30s %s\n' '  just ci' '{{ci_summary}}' >&"${output_fd}"
    printf '\n%s\n' 'Use `just help <recipe>` for detailed usage.' >&"${output_fd}"
  }
  case "{{recipe}}" in
    "")
      show_list
      ;;
    help)
      printf '\n%s\n\n' 'Usage: just help [recipe]'
      printf '%s\n' 'Description:'
      printf '  %s\n\n' '{{help_summary}}'
      printf '%s\n' 'Arguments:'
      printf '%s\n' '  recipe: Optional recipe name for detailed help.'
      printf '%s\n' '    Allowed values: help, build, test, run, clean, doctor, dmg, ci'
      printf '%s\n\n' '    Empty value shows the full command list.'
      printf '%s\n' 'Examples:'
      printf '%s\n' '  just help'
      printf '%s\n' '  just help dmg'
      ;;
    build)
      printf '\n%s\n\n' 'Usage: just build'
      printf '%s\n' 'Description:'
      printf '  %s\n\n' '{{build_summary}}'
      printf '%s\n' 'Examples:'
      printf '%s\n' '  just build'
      ;;
    test)
      printf '\n%s\n\n' 'Usage: just test'
      printf '%s\n' 'Description:'
      printf '  %s\n\n' '{{test_summary}}'
      printf '%s\n' 'Examples:'
      printf '%s\n' '  just test'
      ;;
    run)
      printf '\n%s\n\n' 'Usage: just run'
      printf '%s\n' 'Description:'
      printf '  %s\n\n' '{{run_summary}}'
      printf '%s\n' 'Examples:'
      printf '%s\n' '  just run'
      ;;
    clean)
      printf '\n%s\n\n' 'Usage: just clean'
      printf '%s\n' 'Description:'
      printf '  %s\n\n' '{{clean_summary}}'
      printf '%s\n' 'Examples:'
      printf '%s\n' '  just clean'
      ;;
    doctor)
      printf '\n%s\n\n' 'Usage: just doctor'
      printf '%s\n' 'Description:'
      printf '  %s\n\n' '{{doctor_summary}}'
      printf '%s\n' 'Examples:'
      printf '%s\n' '  just doctor'
      ;;
    dmg)
      printf '\n%s\n\n' 'Usage: just dmg <arch> <version>'
      printf '%s\n' 'Description:'
      printf '  %s\n\n' '{{dmg_summary}}'
      printf '%s\n' 'Arguments:'
      printf '%s\n' '  arch: Target architecture.'
      printf '%s\n' '    Allowed values: arm64, x86_64, universal'
      printf '%s\n' '  version: Arbitrary version string used in the output DMG filename.'
      printf '%s\n\n' '    Example values: 1.03, 1.03-beta1'
      printf '%s\n' 'Examples:'
      printf '%s\n' '  just dmg arm64 1.03'
      printf '%s\n' '  just dmg universal 1.03-beta1'
      ;;
    ci)
      printf '\n%s\n\n' 'Usage: just ci'
      printf '%s\n' 'Description:'
      printf '  %s\n\n' '{{ci_summary}}'
      printf '%s\n' 'Runs:'
      printf '%s\n' '  1. just doctor'
      printf '%s\n' '  2. just build'
      printf '%s\n\n' '  3. just test'
      printf '%s\n' 'Success output:'
      printf "%s\n\n" "  ==> Local CI flow completed successfully."
      printf '%s\n' 'Examples:'
      printf '%s\n' '  just ci'
      ;;
    *)
      printf 'error: unknown recipe `%s`\n' "{{recipe}}" >&2
      show_list 2
      exit 1
      ;;
  esac

# Build the app in Debug mode
build:
  .github/scripts/build-debug.sh

# Run glanceTests in Debug mode
test:
  .github/scripts/test.sh

# Launch the built Debug app
run:
  .github/scripts/run-app.sh

# Remove local build artifacts
clean:
  .github/scripts/clean.sh

# Check required local tools and environment
doctor:
  .github/scripts/doctor.sh

# Build a release DMG (arch: arm64|x86_64|universal, version: e.g. 1.03)
dmg arch version:
  .github/scripts/build-dmg.sh "{{arch}}" "{{version}}"

# Run local CI flow: doctor -> build -> test
ci: doctor build test
  @printf '\n==> Local CI flow completed successfully.\n'
