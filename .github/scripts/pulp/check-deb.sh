#!/usr/bin/env bash
# Verify that the delivered/promoted DEB packages are (1) physically present as
# content units in their target pulp repository and (2) resolvable through the
# published apt metadata (and actually fetchable from the content url).
#
# Metadata resolution mirrors promote-deb.sh: the structured publication serves
# packages under the canonical pool layout, so the published Filename is resolved
# from the suite's Packages index by sha256. Architecture "all" packages are
# listed under every binary-<arch>, so they are looked up across the suite's
# architectures. Each index is read once into a sha256 -> Filename map.
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
declare -A VERSION_URI_BY_REPO   # repo -> uri-encoded latest_version_href, empty when missing
for repo in $(printf '%s\n' "${E_REPOSITORY[@]}" | sort -u); do
  version_href=$(pulp deb repository show --name "$repo" 2>/dev/null | jq -r '.latest_version_href // empty')
  VERSION_URI_BY_REPO[$repo]=""
  if [[ -n "$version_href" ]]; then
    VERSION_URI_BY_REPO[$repo]=$(jq -rn --arg v "$version_href" '$v | @uri')
  else
    echo "[WARN] Repository $repo does not exist or has no version"
  fi
done

declare -A PRESENT_IDX
PRESENCE_DIR=$(mktemp -d)
for i in "${!E_FILENAME[@]}"; do
  version_uri=${VERSION_URI_BY_REPO[${E_REPOSITORY[$i]}]}
  [[ -n "$version_uri" ]] || continue
  url="$PULP_URL/$PULP_DOMAIN/api/v3/content/deb/packages/?repository_version=${version_uri}&sha256=${E_SHA256[$i]}&fields=pulp_href&limit=1"
  # token refreshed in this shell: a refresh inside the job would be lost
  refresh_pulp_token
  (
    count=$(curl -fsSL --retry 3 --retry-delay 5 \
              -H "Authorization: Bearer $PULP_TOKEN" "$url" | jq -r '.count // 0') || {
      echo "[WARN] presence lookup failed for ${E_FILENAME[$i]} in ${E_REPOSITORY[$i]} ($url)" >&2
      exit 0
    }
    [[ "${count:-0}" -gt 0 ]] && touch "$PRESENCE_DIR/$i"
  ) &
  wait_for_slot
done
wait
for i in "${!E_FILENAME[@]}"; do
  PRESENT_IDX[$i]=false
  [[ -e "$PRESENCE_DIR/$i" ]] && PRESENT_IDX[$i]=true
done
rm -rf "$PRESENCE_DIR"

# --- metadata resolvability + fetchability, with a bounded retry window -----
declare -A META_IDX      # idx -> true|false
declare -A RESOLVED_IDX  # idx -> published Filename
for i in "${!E_FILENAME[@]}"; do META_IDX[$i]=false; done

# one resolution round: read each suite's Packages indexes once into a
# sha256 -> Filename map, then resolve each pending package from it
resolve_pending() {
  local -A indexed=()      # key: base_path|suite|arch -> set once read
  local -A filename_by=()  # key: base_path|suite|arch|sha256 -> Filename
  local -A arches_cache=() # key: base_path|suite -> space separated arches
  local all_resolved=true i base_path suite arch search_arches sk ck a filename sha fname
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
      if [[ -z "${indexed[$ck]+set}" ]]; then
        indexed[$ck]=1
        while IFS=$'\t' read -r sha fname; do
          filename_by["$ck|$sha"]=$fname
        done < <(content_curl -fsSL "$PULP_CONTENT_URL/$base_path/dists/$suite/main/binary-$a/Packages" 2>/dev/null |
          awk 'BEGIN { RS = ""; FS = "\n" } {
            sha = ""; fname = ""
            for (i = 1; i <= NF; i++) {
              if ($i ~ /^SHA256: /) sha = substr($i, 9)
              else if ($i ~ /^Filename: /) fname = substr($i, 11)
            }
            if (sha != "" && fname != "") print sha "\t" fname
          }')
      fi
      filename=${filename_by["$ck|${E_SHA256[$i]}"]:-}
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
