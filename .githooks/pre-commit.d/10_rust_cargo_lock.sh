#!/usr/bin/env bash
set -euo pipefail

# Checks that rust-plugins/Cargo.lock is consistent with rust-plugins/Cargo.toml.
#
# 'cargo metadata --locked' resolves the dependency graph and fails when that
# would require updating Cargo.lock, e.g. a dependency added to or changed in
# Cargo.toml without the lockfile being regenerated, or the reverse.
#
# The check only runs when one of these two files is staged.
#
# cargo is optional: when it is missing the hook warns and lets the commit through.
#
# Note that cargo reads the files as they stand in the working tree, not as they
# are staged, which is the same approximation as the other pre-commit checks.

# Directory of this script, without forking to dirname
SCRIPT_DIR="${BASH_SOURCE[0]%/*}"
if [[ "${SCRIPT_DIR}" == "${BASH_SOURCE[0]}" ]]; then
  SCRIPT_DIR='.'
fi
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

CRATE_DIR='rust-plugins'

# Look for a staged manifest or lockfile
MANIFEST_STAGED=false
while IFS= read -r file; do
  case "${file}" in
    "${CRATE_DIR}/Cargo.toml" | "${CRATE_DIR}/Cargo.lock") MANIFEST_STAGED=true ;;
  esac
done < <(git diff --cached --name-only --diff-filter=ACMR)

# Nothing to do, stay quiet
if [[ "${MANIFEST_STAGED}" == false ]]; then
  exit 0
fi

if ! type -p cargo > /dev/null; then
  warning "Could not locate cargo. Skipping the ${CRATE_DIR}/Cargo.lock consistency check."
  warning "Install: https://rustup.rs"
  exit 0
fi

info "Checking that ${CRATE_DIR}/Cargo.lock is consistent with ${CRATE_DIR}/Cargo.toml"
if ! (cd "${CRATE_DIR}" && cargo metadata --locked --format-version 1 > /dev/null 2>&1); then
  info "command: cargo metadata --locked --format-version 1"
  fatal "${CRATE_DIR}/Cargo.lock is out of date: run 'cargo update --workspace' (or any cargo build) in ${CRATE_DIR} and stage Cargo.lock"
fi
info "${CRATE_DIR}/Cargo.lock is consistent with ${CRATE_DIR}/Cargo.toml"
