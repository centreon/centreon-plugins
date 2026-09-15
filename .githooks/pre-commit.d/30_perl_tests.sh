#!/usr/bin/env bash
set -euo pipefail

# Runs the staged Perl unit tests (tests/**/*.t) through yath.
#
# Only the staged test files are run, not the whole suite: the point is to catch
# a test broken while editing it, without paying for the full run on every commit.
#
# yath is optional: when it is missing the hook warns and lets the commit through.
#
# Note that yath runs the file as it stands in the working tree, not as it is
# staged, which is the same approximation as the other pre-commit checks.

# Directory of this script, without forking to dirname
script_dir="${BASH_SOURCE[0]%/*}"
if [[ "${script_dir}" == "${BASH_SOURCE[0]}" ]]; then
  script_dir='.'
fi
# shellcheck source=../lib/common.sh
source "${script_dir}/../lib/common.sh"

# Get the list of staged test files
staged_tests=()
while IFS= read -r file; do
  case "${file}" in
    tests/*.t) staged_tests+=("${file}") ;;
  esac
done < <(git diff --cached --name-only --diff-filter=ACMR)

# Nothing to do, stay quiet
if (( ${#staged_tests[@]} == 0 )); then
  exit 0
fi

# Determining the yath command
yath_path=$(type -p yath || true)
if [[ -z "${yath_path}" ]]; then
  warning "Could not locate yath. Skipping the Perl unit tests for ${#staged_tests[@]} staged file(s):"
  for file in "${staged_tests[@]}"; do
    warning "--> ${file}"
  done
  warning "Install: cpanm Test2::Harness"
  exit 0
fi

tmpfile=$(mktemp) || fatal "Could not create a temporary file"
trap 'rm -f "${tmpfile}"' EXIT

info "Starting Perl unit tests for ${#staged_tests[@]} staged file(s)"
for file in "${staged_tests[@]}"; do
  info "--> ${file}:"
  info "--> Running yath"
  if ! LANG=C "${yath_path}" test "${file}" > "${tmpfile}" 2>&1 < /dev/null; then
    error "Test file ${file} does not pass"
    info "command:  yath test ${file}"
    grep -E '^\( *(DIAG|STDERR|FAILED) *\)|^\[ *FAIL *\]' "${tmpfile}" | head -n 20 || true
  fi
done

if (( errors > 0 )); then
  fatal "${errors} errors found in Perl unit tests pre-commit checks"
fi
info "All Perl unit tests pre-commit checks passed"
