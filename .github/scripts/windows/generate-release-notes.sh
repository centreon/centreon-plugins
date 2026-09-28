#!/usr/bin/env bash
# Generate GitHub release notes grouped by Centreon conventional-commit type.
#
# Emits one markdown section per change type, and ONLY when that section has at
# least one item. Each item is the subject line of a commit that modified one of
# the given paths, within the given range.
#
# Usage:
#   generate-release-notes.sh <since_ref> <path> [<path> ...]
#     <since_ref> : git ref to start from (exclusive). Empty => full history.
#     <path...>   : paths whose changes are relevant to this release.
set -euo pipefail

since_ref="${1:-}"
shift || true
paths=("$@")

if [[ -n "${since_ref}" ]]; then
  range="${since_ref}..HEAD"
else
  range="HEAD"
fi

# Record separator = 0x1e, field separator = 0x1f (safe: never appear in commit text).
git log "${range}" --no-merges --format=$'\x1e%H\x1f%s\x1f%b' -- "${paths[@]}" | awk '
  BEGIN { RS = "\036"; FS = "\037" }

  function section(title, arr, n,   i) {
    if (n == 0) return
    if (shown++) print ""
    print title
    for (i = 1; i <= n; i++) print "- " arr[i]
  }

  NF < 2 { next }
  {
    subject = $2
    body = $3
    if (seen[subject]++) next

    type = ""
    if (match(subject, /^[a-z]+/)) {
      type = substr(subject, RSTART, RLENGTH)
    }
    breaking = (subject ~ /^[a-z]+(\([^)]*\))?!:/) || (body ~ /BREAKING[ -]CHANGE/)

    if (breaking)             { enhBreaking[++nb] = subject }
    else if (type == "feat")  { feat[++nf] = subject }
    else if (type == "enh")   { enh[++ne] = subject }
    else if (type == "fix")   { fix[++nx] = subject }
  }

  END {
    section("## Enhancements", enh, ne)
    section("## Features", feat, nf)
    section("## Bug fixes", fix, nx)
    section("## Breaking changes", enhBreaking, nb)
  }
'
