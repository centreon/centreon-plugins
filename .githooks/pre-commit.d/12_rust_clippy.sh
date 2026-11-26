#!/usr/bin/env bash
set -euo pipefail

# Runs clippy on rust-plugins with warnings denied, as the 'lint' job of the
# generic-plugins workflow does, so that a lint is caught at commit time rather
# than after a CI round trip.
#
# clippy runs on the stable toolchain pinned by rust-plugins/rust-toolchain.toml,
# which rustup selects (and installs if needed) for any cargo command run in
# that directory.
#
# The check only runs when a file that can change clippy's result is staged:
# a Rust source file, the grammar, the build script, the manifest, the lockfile,
# the toolchain pin or the clippy configuration. It checks the whole crate, as the CI does, which takes
# a few seconds to a minute depending on what is already built.
#
# cargo is optional: when it is missing the hook warns and lets the commit through.
#
# Note that clippy reads the files as they stand in the working tree, not as they
# are staged, which is the same approximation as the other pre-commit checks.

# Directory of this script, without forking to dirname
SCRIPT_DIR="${BASH_SOURCE[0]%/*}"
if [[ "${SCRIPT_DIR}" == "${BASH_SOURCE[0]}" ]]; then
  SCRIPT_DIR='.'
fi
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

CRATE_DIR='rust-plugins'

# Look for a staged file that can change clippy's result
RUST_STAGED=false
while IFS= read -r file; do
  case "${file}" in
    "${CRATE_DIR}"/*.rs | "${CRATE_DIR}"/*.lalrpop | \
    "${CRATE_DIR}/Cargo.toml" | "${CRATE_DIR}/Cargo.lock" | "${CRATE_DIR}/rust-toolchain.toml" | \
    "${CRATE_DIR}/clippy.toml")
      RUST_STAGED=true
      ;;
  esac
done < <(git diff --cached --name-only --diff-filter=ACMR)

# Nothing to do, stay quiet
if [[ "${RUST_STAGED}" == false ]]; then
  exit 0
fi

if ! type -p cargo > /dev/null; then
  warning "Could not locate cargo. Skipping the ${CRATE_DIR} clippy check."
  warning "Install: https://rustup.rs"
  exit 0
fi

info "Running clippy on ${CRATE_DIR} (cargo clippy --all-targets --release -- -D warnings)"
if ! (cd "${CRATE_DIR}" && cargo clippy --all-targets --release --quiet -- -D warnings); then
  info "command:  cd ${CRATE_DIR} && cargo clippy --all-targets --release -- -D warnings"
  fatal "clippy reports warnings in ${CRATE_DIR}: fix them, or run 'cargo clippy --fix' in ${CRATE_DIR}, and stage the result"
fi
info "clippy reports no warnings in ${CRATE_DIR}"
