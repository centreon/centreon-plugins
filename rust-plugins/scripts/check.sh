#!/usr/bin/env bash
set -euo pipefail

# Quality gate for rust-plugins: runs locally what the 'lint' and 'build' jobs
# of .github/workflows/generic-plugins.yml enforce, to catch issues before
# pushing instead of waiting for a CI round trip:
#   - Cargo.lock consistent with Cargo.toml
#   - formatting, on the same dated nightly as the CI (rustfmt.toml relies on
#     nightly-only options)
#   - clippy with warnings denied, on the stable toolchain of rust-toolchain.toml,
#     including the no-panic lints declared under [lints.clippy] in Cargo.toml
#   - unit tests, benches included
#
# Usage: scripts/check.sh (from any directory)

# Run from the crate root, wherever the script is called from
SCRIPT_DIR="${BASH_SOURCE[0]%/*}"
if [[ "${SCRIPT_DIR}" == "${BASH_SOURCE[0]}" ]]; then
  SCRIPT_DIR='.'
fi
cd "${SCRIPT_DIR}/.."

# Same dated nightly as the 'lint' job of .github/workflows/generic-plugins.yml
# and .githooks/pre-commit.d/11_rust_fmt.sh
NIGHTLY_TOOLCHAIN="$(< rustfmt-toolchain.txt)"

step() {
  echo "==> $*"
}

step "Cargo.lock consistency"
if ! cargo metadata --locked --format-version 1 > /dev/null; then
  echo "FAILED: Cargo.lock is out of date: run 'cargo update --workspace' and commit Cargo.lock"
  exit 1
fi

step "cargo +${NIGHTLY_TOOLCHAIN} fmt --check"
if ! rustup run "${NIGHTLY_TOOLCHAIN}" rustfmt --version > /dev/null 2>&1; then
  echo "FAILED: rustfmt for ${NIGHTLY_TOOLCHAIN} is missing"
  echo "Install: rustup toolchain install ${NIGHTLY_TOOLCHAIN} --profile minimal --component rustfmt"
  exit 1
fi
cargo "+${NIGHTLY_TOOLCHAIN}" fmt --check

step "cargo clippy --all-targets --release -- -D warnings"
cargo clippy --all-targets --release --quiet -- -D warnings

# --all-targets also builds the benches, which run once in test mode: criterion,
# a bench-only dev-dependency, is otherwise reported as an unused dependency.
step "cargo test --all-targets"
cargo test --all-targets --quiet

echo "ALL CHECKS PASSED"
