#!/usr/bin/env bash
# Verify that the delivered/promoted RPM packages are (1) physically present as
# content units in their target pulp repository and (2) resolvable through the
# published repodata (and actually fetchable from the content url).
#
# The expected list is the manifest emitted by the delivery/promote step. The
# script never exits early — see check-common.sh.
set -uo pipefail

# shellcheck source=.github/scripts/pulp/check-common.sh
source "$(dirname "$0")/check-common.sh"

load_expected "RPM"

# --- load expected packages into parallel arrays ---------------------------
mapfile -t E_FILENAME   < <(echo "$PACKAGES_JSON" | jq -r '.[].filename')
mapfile -t E_ARCH       < <(echo "$PACKAGES_JSON" | jq -r '.[].arch')
mapfile -t E_SHA256     < <(echo "$PACKAGES_JSON" | jq -r '.[].sha256')
mapfile -t E_REPOSITORY < <(echo "$PACKAGES_JSON" | jq -r '.[].repository')
mapfile -t E_BASEPATH   < <(echo "$PACKAGES_JSON" | jq -r '.[].base_path')

# --- physical presence: content units in each repository's latest version --
# newest first, stopping as soon as every expected package of the repository
# has been seen: a large repository makes deep offset pagination costly and
# flaky, while the freshly delivered packages are the newest content by
# construction.
# The listing goes to a file and grep reads the file: piping it into grep -q
# would SIGPIPE the writer on the (early-exiting) first match, and pipefail
# then turns every successful match into a false negative.
declare -A PRESENT_BY_REPO   # repo -> file holding one filename per line
declare -A EXPECTED_COUNT_BY_REPO
declare -A TOTAL_COUNT_BY_REPO

for repo in $(printf '%s\n' "${E_REPOSITORY[@]}" | sort -u); do
  PRESENT_BY_REPO[$repo]=$(mktemp)
  version_href=$(pulp rpm repository show --name "$repo" 2>/dev/null | jq -r '.latest_version_href // empty')
  if [[ -z "$version_href" ]]; then
    echo "[WARN] Repository $repo does not exist or has no version"
    continue
  fi
  url="$PULP_URL/$PULP_DOMAIN/api/v3/content/rpm/packages/?$(
    printf 'repository_version=%s&pulp_label_select=%s&ordering=-pulp_created&limit=1000' \
      "$(jq -rn --arg v "$version_href" '$v | @uri')" \
      "$(jq -rn --arg v "module=$MODULE_NAME" '$v | @uri')"
  )"
  pages=0
  while [[ -n "$url" ]] && ((pages < 20)); do
    page=$(curl -fsSL -H "Authorization: Bearer $PULP_TOKEN" "$url") || {
      echo "[WARN] presence page fetch failed for $repo ($url)" >&2
      break
    }
    if ((pages == 0)); then
      TOTAL_COUNT_BY_REPO[$repo]=$(echo "$page" | jq -r '.count')
      echo "[INFO] Repository $repo holds ${TOTAL_COUNT_BY_REPO[$repo]} module package(s) in its latest version"
    fi
    echo "$page" | jq -r '.results[].location_href' | awk -F/ '{print $NF}' >> "${PRESENT_BY_REPO[$repo]}"
    pages=$((pages + 1))
    all_found=true
    for i in "${!E_FILENAME[@]}"; do
      [[ "${E_REPOSITORY[$i]}" == "$repo" ]] || continue
      if ! grep -Fxq "${E_FILENAME[$i]}" "${PRESENT_BY_REPO[$repo]}"; then
        all_found=false
        break
      fi
    done
    [[ "$all_found" == "true" ]] && break
    url=$(echo "$page" | jq -r '.next // empty')
  done
done

declare -A PRESENT_IDX   # idx -> true|false
for i in "${!E_FILENAME[@]}"; do
  repo=${E_REPOSITORY[$i]}
  EXPECTED_COUNT_BY_REPO[$repo]=$(( ${EXPECTED_COUNT_BY_REPO[$repo]:-0} + 1 ))
  if grep -Fxq "${E_FILENAME[$i]}" "${PRESENT_BY_REPO[$repo]}"; then
    PRESENT_IDX[$i]=true
  else
    PRESENT_IDX[$i]=false
  fi
done

# right number (delivery only): warn when the repository holds more module
# packages than expected. Count-based only: with shared repositories and the
# daily develop deliveries, listing every extra name is noise (and the full
# listing is what the bounded pagination above avoids).
[[ "${CHECK_MODE:-delivery}" == "delivery" ]] && for repo in "${!EXPECTED_COUNT_BY_REPO[@]}"; do
  total=${TOTAL_COUNT_BY_REPO[$repo]:-0}
  if [[ "$total" -gt "${EXPECTED_COUNT_BY_REPO[$repo]}" ]]; then
    echo "::warning::Repository $repo holds $total module packages, ${EXPECTED_COUNT_BY_REPO[$repo]} delivered by this run (older builds and other modules accumulate until cleanup)"
  fi
done

# --- metadata resolvability + fetchability, with a bounded retry window -----
declare -A META_IDX      # idx -> true|false
declare -A RESOLVED_IDX  # idx -> published location href
for i in "${!E_FILENAME[@]}"; do META_IDX[$i]=false; done

# resolve the published location href of the package whose sha256 checksum
# matches, from a primary.xml body: matching by checksum (not filename) binds
# the verification to the exact delivered content, like the DEB by-sha256 match
resolve_href() {
  # read the primary.xml from a file: awk exits on the first match, and a pipe
  # writer would take a SIGPIPE ("printf: write error: Broken pipe" noise)
  local primary_file=$1 sha=$2
  [[ -s "$primary_file" ]] || return 0
  awk -v sha="$sha" '
    BEGIN { RS = "</package>" }
    index($0, ">" sha "</checksum>") {
      if (match($0, /<location[^>]*href="[^"]+"/)) {
        s = substr($0, RSTART, RLENGTH)
        sub(/.*href="/, "", s); sub(/"$/, "", s)
        print s; exit
      }
    }' "$primary_file"
}

# one resolution round: fetch each base_path's primary.xml once, then resolve
# each pending package's published href by sha256
resolve_pending() {
  local -A primary_cache=()
  local all_resolved=true i base_path repomd primary_href href cache_file
  for i in "${!E_FILENAME[@]}"; do
    [[ "${META_IDX[$i]}" == "true" ]] && continue
    base_path=${E_BASEPATH[$i]}

    if [[ -z "${primary_cache[$base_path]+set}" ]]; then
      cache_file=$(mktemp)
      repomd=$(content_curl -fsSL "$PULP_CONTENT_URL/$PULP_DOMAIN/$base_path/repodata/repomd.xml" 2>/dev/null || true)
      primary_href=$(printf '%s' "$repomd" | grep -oP '<location href="\K[^"]+primary\.xml[^"]*' | head -1 || true)
      if [[ -n "$primary_href" ]]; then
        content_curl -fsSL "$PULP_CONTENT_URL/$PULP_DOMAIN/$base_path/$primary_href" 2>/dev/null | gunzip -c 2>/dev/null > "$cache_file" || true
      fi
      primary_cache[$base_path]=$cache_file
    fi

    href=$(resolve_href "${primary_cache[$base_path]}" "${E_SHA256[$i]}")
    if [[ -n "$href" ]]; then
      META_IDX[$i]=true
      RESOLVED_IDX[$i]=$href
    else
      all_resolved=false
    fi
  done
  rm -f "${primary_cache[@]}"
  [[ "$all_resolved" == "true" ]]
}

wait_for_metadata
check_fetchable_and_record
render_summary
