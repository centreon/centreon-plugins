#!/usr/bin/env bash
#
# Quality gate for rust-plugins — matches what the "lint" and "build" jobs of
# .github/workflows/generic-plugins.yml enforce in CI. Run it locally before
# pushing to catch issues without waiting on a CI round trip.
#
# The reachable-panic scan below is not currently part of the CI gate: it is
# a stricter, complementary local check — a panic!/unwrap() reachable from
# untrusted input (a malformed JSON definition, a malicious SNMP response)
# turns a reportable UNKNOWN into a plugin crash.

set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> cargo fmt --check"
cargo fmt --check

echo "==> cargo clippy --all-targets -- -D warnings"
cargo clippy --all-targets --quiet -- -D warnings

echo "==> cargo test"
cargo test --quiet

echo "==> reachable panic scan (production code, outside #[cfg(test)])"
# panic!/unwrap()/todo!/unreachable! are only tolerated inside test modules:
# for each source file, scan the content BEFORE its first #[cfg(test)] marker.
fail=0
while IFS= read -r -d '' file; do
    hits=$(awk '/#\[cfg\(test\)\]/{exit} {print NR": "$0}' "$file" \
        | grep -E 'panic!|\.unwrap\(\)|todo!\(|unreachable!' || true)
    if [ -n "$hits" ]; then
        echo "reachable panic/unwrap in $file:"
        echo "$hits"
        fail=1
    fi
done < <(find src -name '*.rs' -print0)
if [ "$fail" -ne 0 ]; then
    echo "FAILED: reachable panics found outside test modules"
    exit 1
fi

echo "ALL CHECKS PASSED"
