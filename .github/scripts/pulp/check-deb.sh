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

# --- physical presence: content units in the repository's latest version ----
# one lookup per expected package, by sha256 within the repository version: the
# shared repositories hold 10k+ packages and listing them, even newest first,
# is slow enough to hit the gateway timeout, which then read as "absent" while
# the package was published and fetchable. --retry covers those transient 5xx.
declare -A VERSION_BY_REPO   # repo -> latest_version_href, empty when missing
for repo in $(printf '%s\n' "${E_REPOSITORY[@]}" | sort -u); do
  VERSION_BY_REPO[$repo]=$(pulp deb repository show --name "$repo" 2>/dev/null | jq -r '.latest_version_href // empty')
  [[ -n "${VERSION_BY_REPO[$repo]}" ]] || echo "[WARN] Repository $repo does not exist or has no version"
done

declare -A PRESENT_IDX
for i in "${!E_FILENAME[@]}"; do
  PRESENT_IDX[$i]=false
  version_href=${VERSION_BY_REPO[${E_REPOSITORY[$i]}]}
  [[ -n "$version_href" ]] || continue
  ((i % 40 == 0)) && refresh_pulp_token
  url="$PULP_URL/$PULP_DOMAIN/api/v3/content/deb/packages/?$(
    printf 'repository_version=%s&sha256=%s&fields=pulp_href&limit=1' \
      "$(jq -rn --arg v "$version_href" '$v | @uri')" "${E_SHA256[$i]}"
  )"
  count=$(curl -fsSL --retry 3 --retry-delay 5 \
            -H "Authorization: Bearer $PULP_TOKEN" "$url" | jq -r '.count // 0') || {
    echo "[WARN] presence lookup failed for ${E_FILENAME[$i]} in ${E_REPOSITORY[$i]} ($url)" >&2
    continue
  }
  [[ "${count:-0}" -gt 0 ]] && PRESENT_IDX[$i]=true
done

# --- metadata resolvability + fetchability, with a bounded retry window -----
# resolve a package's published Filename from a suite Packages index by sha256
resolve_filename() {
  # read the Packages index from a file: awk exits on the first match, and a
  # pipe writer would take a SIGPIPE ("printf: write error: Broken pipe" noise)
  local packages_file=$1 sha=$2
  [[ -s "$packages_file" ]] || return 0
  awk -v sha="$sha" '
    BEGIN { RS = ""; FS = "\n" }
    index($0, "SHA256: " sha) {
      for (i = 1; i <= NF; i++) if ($i ~ /^Filename: /) { sub(/^Filename: /, "", $i); print $i; exit }
    }' "$packages_file"
}

declare -A META_IDX      # idx -> true|false
declare -A RESOLVED_IDX  # idx -> published Filename
for i in "${!E_FILENAME[@]}"; do META_IDX[$i]=false; done

# one resolution round: fetch each suite's Packages indexes once, then resolve
# each pending package's published Filename by sha256
resolve_pending() {
  local -A pkg_cache=()    # key: base_path|suite|arch -> Packages index file
  local -A arches_cache=() # key: base_path|suite -> space separated arches
  local all_resolved=true i base_path suite arch search_arches sk ck a filename cache_file
  for i in "${!E_FILENAME[@]}"; do
    [[ "${META_IDX[$i]}" == "true" ]] && continue
    base_path=${E_BASEPATH[$i]}; suite=${E_SUITE[$i]}; arch=${E_ARCH[$i]}

    # architectures to search: the package arch, plus every arch of the suite
    # for "all" packages (which are duplicated across each binary-<arch>)
    search_arches="$arch"
    if [[ "$arch" == "all" ]]; then
      sk="$base_path|$suite"
      if [[ -z "${arches_cache[$sk]+set}" ]]; then
        arches_cache[$sk]=$(content_curl -fsSL "$PULP_CONTENT_URL/$base_path/dists/$suite/Release" 2>/dev/null \
          | awk -F': ' '/^Architectures:/ { print $2; exit }')
      fi
      search_arches="${arches_cache[$sk]:-amd64 arm64 all}"
    fi

    filename=""
    for a in $search_arches; do
      ck="$base_path|$suite|$a"
      if [[ -z "${pkg_cache[$ck]+set}" ]]; then
        cache_file=$(mktemp)
        content_curl -fsSL "$PULP_CONTENT_URL/$base_path/dists/$suite/main/binary-$a/Packages" 2>/dev/null > "$cache_file" || true
        pkg_cache[$ck]=$cache_file
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
  rm -f "${pkg_cache[@]}"
  [[ "$all_resolved" == "true" ]]
}

wait_for_metadata
check_fetchable_and_record
render_summary
