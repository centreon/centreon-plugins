#!/usr/bin/env bash
set -euo pipefail

# Checks that rust-plugins is formatted as the 'lint' job of the generic-plugins
# workflow expects it.
#
# rust-plugins/rustfmt.toml uses options that are only available on the nightly
# channel, so the check runs 'cargo fmt --check' on the same dated nightly as
# the CI: a stable rustfmt would ignore those options and format differently.
#
# The check only runs when a Rust source file, the rustfmt configuration or the
# nightly pin of rust-plugins is staged. It checks the whole crate, as the CI does.
#
# The nightly toolchain is optional: when rustup or that toolchain is missing the
# hook warns and lets the commit through.
#
# Note that rustfmt reads the files as they stand in the working tree, not as they
# are staged, which is the same approximation as the other pre-commit checks.

# Directory of this script, without forking to dirname
SCRIPT_DIR="${BASH_SOURCE[0]%/*}"
if [[ "${SCRIPT_DIR}" == "${BASH_SOURCE[0]}" ]]; then
  SCRIPT_DIR='.'
fi
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

CRATE_DIR='rust-plugins'
# Same dated nightly as the 'lint' job of .github/workflows/generic-plugins.yml
# and rust-plugins/scripts/check.sh
NIGHTLY_TOOLCHAIN="$(< "${CRATE_DIR}/rustfmt-toolchain.txt")"

# Look for a staged Rust source file or rustfmt configuration
RUST_STAGED=false
while IFS= read -r file; do
  case "${file}" in
    "${CRATE_DIR}"/*.rs | "${CRATE_DIR}/rustfmt.toml" | "${CRATE_DIR}/.rustfmt.toml" | \
    "${CRATE_DIR}/rustfmt-toolchain.txt")
      RUST_STAGED=true
      ;;
  esac
done < <(git diff --cached --name-only --diff-filter=ACMR)

# Nothing to do, stay quiet
if [[ "${RUST_STAGED}" == false ]]; then
  exit 0
fi

if ! type -p rustup > /dev/null; then
  warning "Could not locate rustup. Skipping the ${CRATE_DIR} formatting check."
  warning "Install: https://rustup.rs"
  exit 0
fi

if ! rustup run "${NIGHTLY_TOOLCHAIN}" rustfmt --version > /dev/null 2>&1; then
  warning "Could not locate rustfmt for ${NIGHTLY_TOOLCHAIN}. Skipping the ${CRATE_DIR} formatting check."
  warning "Install: rustup toolchain install ${NIGHTLY_TOOLCHAIN} --profile minimal --component rustfmt"
  exit 0
fi

info "Checking the formatting of ${CRATE_DIR} with ${NIGHTLY_TOOLCHAIN}"
if ! (cd "${CRATE_DIR}" && cargo "+${NIGHTLY_TOOLCHAIN}" fmt --check); then
  fatal "${CRATE_DIR} is not formatted: run 'cargo +${NIGHTLY_TOOLCHAIN} fmt' in ${CRATE_DIR} and stage the result"
fi
info "${CRATE_DIR} is correctly formatted"
