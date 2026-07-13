#!/usr/bin/env bash
# Verify that the delivered/promoted DEB packages are (1) physically present as
# content units in their target pulp repository and (2) resolvable through the
# published apt metadata (and actually fetchable from the content url).
#
# Metadata resolution mirrors promote-deb.sh: the structured publication serves
# packages under the canonical pool layout, so the published Filename is resolved
# from the suite's Packages index by sha256. Architecture "all" packages are
# listed under every binary-<arch>, so they are looked up across the suite's
# architectures.
#
# The expected list is the manifest emitted by the delivery/promote step. The
# script never exits early — see check-common.sh.
set -uo pipefail

# shellcheck source=.github/scripts/pulp/check-common.sh
source "$(dirname "$0")/check-common.sh"

load_expected "DEB"

# --- load expected packages into parallel arrays ---------------------------
mapfile -t E_FILENAME   < <(echo "$PACKAGES_JSON" | jq -r '.[].filename')
mapfile -t E_ARCH       < <(echo "$PACKAGES_JSON" | jq -r '.[].arch')
mapfile -t E_SHA256     < <(echo "$PACKAGES_JSON" | jq -r '.[].sha256')
mapfile -t E_REPOSITORY < <(echo "$PACKAGES_JSON" | jq -r '.[].repository')
mapfile -t E_BASEPATH   < <(echo "$PACKAGES_JSON" | jq -r '.[].base_path')
mapfile -t E_SUITE      < <(echo "$PACKAGES_JSON" | jq -r '.[].suite')
mapfile -t E_RELPATH    < <(echo "$PACKAGES_JSON" | jq -r '.[].relative_path')

# --- physical presence: content units in the repository's latest version ----
declare -A PRESENT_BY_REPO
for repo in $(printf '%s\n' "${E_REPOSITORY[@]}" | sort -u); do
  version_href=$(pulp deb repository show --name "$repo" 2>/dev/null | jq -r '.latest_version_href // empty')
  if [[ -z "$version_href" ]]; then
    echo "[WARN] Repository $repo does not exist or has no version"
    PRESENT_BY_REPO[$repo]=""
    continue
  fi
  PRESENT_BY_REPO[$repo]=$(
    curl -fsSL -H "Authorization: Github $PULP_TOKEN" -G \
      --data-urlencode "repository_version=$version_href" \
      --data-urlencode "pulp_label_select=module=$MODULE_NAME" \
      --data-urlencode "limit=1000" \
      "$PULP_URL/api/v3/content/deb/packages/" 2>/dev/null \
      | jq -r '.results[].relative_path'
  )
done

declare -A PRESENT_IDX
for i in "${!E_FILENAME[@]}"; do
  if printf '%s\n' "${PRESENT_BY_REPO[${E_REPOSITORY[$i]}]:-}" | grep -Fxq "${E_RELPATH[$i]}"; then
    PRESENT_IDX[$i]=true
  else
    PRESENT_IDX[$i]=false
  fi
done

# --- metadata resolvability + fetchability, with a bounded retry window -----
# resolve a package's published Filename from a suite Packages index by sha256
resolve_filename() {
  local packages=$1 sha=$2
  printf '%s' "$packages" | awk -v sha="$sha" '
    BEGIN { RS = ""; FS = "\n" }
    index($0, "SHA256: " sha) {
      for (i = 1; i <= NF; i++) if ($i ~ /^Filename: /) { sub(/^Filename: /, "", $i); print $i; exit }
    }'
}

declare -A META_IDX      # idx -> true|false
declare -A RESOLVED_IDX  # idx -> published Filename
for i in "${!E_FILENAME[@]}"; do META_IDX[$i]=false; done

# one resolution round: fetch each suite's Packages indexes once, then resolve
# each pending package's published Filename by sha256
resolve_pending() {
  local -A pkg_cache=()    # key: base_path|suite|arch -> Packages body
  local -A arches_cache=() # key: base_path|suite -> space separated arches
  local all_resolved=true i base_path suite arch search_arches sk ck a filename
  for i in "${!E_FILENAME[@]}"; do
    [[ "${META_IDX[$i]}" == "true" ]] && continue
    base_path=${E_BASEPATH[$i]}; suite=${E_SUITE[$i]}; arch=${E_ARCH[$i]}

    # architectures to search: the package arch, plus every arch of the suite
    # for "all" packages (which are duplicated across each binary-<arch>)
    search_arches="$arch"
    if [[ "$arch" == "all" ]]; then
      sk="$base_path|$suite"
      if [[ -z "${arches_cache[$sk]+set}" ]]; then
        arches_cache[$sk]=$(curl -fsSL "$PULP_CONTENT_URL/$base_path/dists/$suite/Release" 2>/dev/null \
          | awk -F': ' '/^Architectures:/ { print $2; exit }')
      fi
      search_arches="${arches_cache[$sk]:-amd64 arm64 all}"
    fi

    filename=""
    for a in $search_arches; do
      ck="$base_path|$suite|$a"
      if [[ -z "${pkg_cache[$ck]+set}" ]]; then
        pkg_cache[$ck]=$(curl -fsSL "$PULP_CONTENT_URL/$base_path/dists/$suite/main/binary-$a/Packages" 2>/dev/null || true)
      fi
      filename=$(resolve_filename "${pkg_cache[$ck]}" "${E_SHA256[$i]}")
      [[ -n "$filename" ]] && break
    done

    if [[ -n "$filename" ]]; then
      META_IDX[$i]=true
      RESOLVED_IDX[$i]=$filename
    else
      all_resolved=false
    fi
  done
  [[ "$all_resolved" == "true" ]]
}

wait_for_metadata
check_fetchable_and_record
render_summary
