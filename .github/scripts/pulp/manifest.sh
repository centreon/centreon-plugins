#!/usr/bin/env bash
# Shared helpers to emit the delivery/promotion manifest consumed by the
# verification scripts (check-rpm.sh, check-deb.sh). Source this file, append
# one compact JSON object per package with manifest_add, then finalize the
# manifest with manifest_write.
#
# The manifest is the authoritative "expected packages" list: it is captured at
# the moment of upload (the packages that were on the runner before/at upload),
# so the check step verifies exactly this set rather than re-reading the build
# cache. Each entry carries the package identity (for the content-api presence
# query), its sha256 (for the by-checksum metadata match) and the pulp target
# coordinates (so the check re-derives no path).

MANIFEST_ENTRIES=()

# manifest_add <compact-json-object>
manifest_add() {
  MANIFEST_ENTRIES+=("$1")
}

# manifest_write <module> <distrib> <package_type> <stability> <mode> <content_url>
# writes the manifest json to the workspace and exposes its path as the
# "manifest" step output when running inside a github action.
manifest_write() {
  local module=$1 distrib=$2 package_type=$3 stability=$4 mode=$5 content_url=$6
  local file="${GITHUB_WORKSPACE:-$PWD}/pulp-delivery-manifest.json"
  local packages="[]"
  if ((${#MANIFEST_ENTRIES[@]})); then
    packages=$(printf '%s\n' "${MANIFEST_ENTRIES[@]}" | jq -s '.')
  fi

  # NB: the jq variable is named module_name, not module — `module` is a reserved
  # jq keyword and `$module` fails to parse on stricter jq builds (the CI runner)
  jq -n \
    --arg module_name "$module" \
    --arg distrib "$distrib" \
    --arg package_type "$package_type" \
    --arg stability "$stability" \
    --arg mode "$mode" \
    --arg content_url "$content_url" \
    --argjson packages "$packages" \
    '{
      "module": $module_name,
      distrib: $distrib,
      package_type: $package_type,
      stability: $stability,
      mode: $mode,
      pulp_content_url: $content_url,
      packages: $packages
    }' > "$file"

  echo "[INFO] Wrote delivery manifest ($(echo "$packages" | jq 'length') package(s)) to $file"
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    echo "manifest=$file" >> "$GITHUB_OUTPUT"
  fi
}
