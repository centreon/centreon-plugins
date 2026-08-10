#!/usr/bin/env bash
# Shared helpers for the pulp delivery/promotion verification scripts
# (check-rpm.sh, check-deb.sh).
#
# The check never aborts mid-verification: every expected package is checked, its
# per-package result is recorded, the full table is rendered to the step summary,
# and only then is a non-zero status returned if anything failed. Source this
# file, call load_expected, verify the packages, then call render_summary.

# authenticated content fetches (content_curl) and token refresh
# shellcheck source=.github/scripts/pulp/api.sh
source "$(dirname "${BASH_SOURCE[0]}")/api.sh"

PULP_URL="${PULP_URL:-https://pulp-api.apps.centreon.com}"
PULP_CONTENT_URL="${PULP_CONTENT_URL:-https://packages.apps.centreon.com}"
# 900s: the published indexes can lag a finished publication by up to the
# content-app cache TTL (600s), the window must survive that worst case
METADATA_TIMEOUT="${METADATA_TIMEOUT:-900}"
METADATA_INTERVAL="${METADATA_INTERVAL:-15}"

# accumulated per-package result rows and the aggregate failure flag
ROWS=()
PRESENT_OK=0
META_OK=0
TOTAL=0
FAILED=0

# load_expected <package_type> — load the manifest emitted by the delivery or
# promotion step into PACKAGES_JSON/COUNT; the manifest is required.
load_expected() {
  local package_type=$1
  if [[ -z "${MANIFEST:-}" || ! -s "${MANIFEST:-}" ]]; then
    echo "::error::pulp verification requires the manifest emitted by the delivery/promote step"
    exit 1
  fi
  echo "[INFO] Reading expected ${package_type} packages from manifest ${MANIFEST}"
  PACKAGES_JSON=$(jq -c '.packages' "$MANIFEST")
  COUNT=$(echo "$PACKAGES_JSON" | jq 'length')
  if [[ "$COUNT" -eq 0 ]]; then
    echo "::error::No expected ${package_type} package to verify"
    exit 1
  fi
  echo "[INFO] ${COUNT} expected ${package_type} package(s) to verify"
}

# wait_for_metadata — repeatedly call the sourcing script's resolve_pending (one
# resolution round over the still-unresolved packages, returning 0 once none
# remain) until everything resolves, METADATA_TIMEOUT is reached, or the
# resolution stalls. The retry window only covers publication propagation: once
# a round reads the published metadata and resolves nothing new while some
# packages already resolved, the remaining ones are not in the publication at
# all (e.g. evicted by the retention policy) and no amount of waiting will
# surface them - report them right away instead of burning the whole window.
wait_for_metadata() {
  local deadline=$(( SECONDS + METADATA_TIMEOUT ))
  local resolved previous_resolved=-1 stall_rounds=0
  until resolve_pending; do
    resolved=0
    for i in "${!E_FILENAME[@]}"; do
      [[ "${META_IDX[$i]}" == "true" ]] && resolved=$((resolved + 1))
    done
    if ((resolved > 0 && resolved == previous_resolved)); then
      stall_rounds=$((stall_rounds + 1))
    else
      stall_rounds=0
    fi
    # several consecutive stalled rounds before giving up: a single one is
    # not enough, the published index can lag the publication by minutes
    # (content-app cache TTL), which read as false negatives on freshly
    # delivered builds
    if ((stall_rounds >= 6)); then
      echo "[WARN] ${resolved}/${#E_FILENAME[@]} package(s) resolvable in the published metadata and no progress in the last 6 rounds; the remaining ones are not part of the publication, giving up early"
      break
    fi
    previous_resolved=$resolved
    if [[ "$SECONDS" -ge "$deadline" ]]; then
      echo "[WARN] Metadata resolution timed out after ${METADATA_TIMEOUT}s (${resolved}/${#E_FILENAME[@]} resolvable)"
      break
    fi
    echo "[INFO] ${resolved}/${#E_FILENAME[@]} package(s) resolvable, waiting ${METADATA_INTERVAL}s for the metadata to propagate..."
    sleep "$METADATA_INTERVAL"
  done
}

# record_row <filename> <arch> <present:bool> <in_metadata:bool> <fetchable:bool>
record_row() {
  local filename=$1 arch=$2 present=$3 in_meta=$4 fetchable=$5
  local p m f
  TOTAL=$((TOTAL + 1))
  if [[ "$present" == "true" ]]; then p="✅"; PRESENT_OK=$((PRESENT_OK + 1)); else p="❌"; FAILED=1; fi
  if [[ "$in_meta" == "true" ]]; then m="✅"; META_OK=$((META_OK + 1)); else m="❌"; FAILED=1; fi
  if [[ "$fetchable" == "true" ]]; then f="✅"; else f="❌"; FAILED=1; fi
  ROWS+=("| \`$filename\` | $arch | $p | $m | $f |")
  echo "[CHECK] $filename ($arch): present=$p metadata=$m fetchable=$f"
}

# check_fetchable_and_record — HEAD each resolved package on the content url and
# record every package's result row. Uses the E_FILENAME/E_ARCH/E_BASEPATH,
# PRESENT_IDX, META_IDX and RESOLVED_IDX arrays filled by the sourcing script.
check_fetchable_and_record() {
  local i url code fetchable attempt
  for i in "${!E_FILENAME[@]}"; do
    fetchable=false
    if [[ "${META_IDX[$i]}" == "true" ]]; then
      url="${PULP_CONTENT_URL}/${E_BASEPATH[$i]}/${RESOLVED_IDX[$i]}"
      # retry: one flaky HEAD out of hundreds (content-app/S3 hiccup) must not
      # fail the whole verification
      for attempt in 1 2 3; do
        code=$(content_curl -fsSL -o /dev/null -w '%{http_code}' -I "$url" 2>/dev/null || echo 000)
        [[ "$code" == "200" ]] && { fetchable=true; break; }
        sleep 2
      done
    fi
    record_row "${E_FILENAME[$i]}" "${E_ARCH[$i]}" "${PRESENT_IDX[$i]}" "${META_IDX[$i]}" "$fetchable"
  done
}

# render_summary — write the per-OS table to the step summary (and stdout), then
# return non-zero if any package failed any check. Called once, after all checks.
render_summary() {
  local title
  title="### ${DISTRIB:-?} — ${STABILITY:-?} (${CHECK_MODE:-delivery}, pulp)"

  {
    echo "$title"
    echo ""
    echo "| Package | Arch | On repository | In metadata | Fetchable |"
    echo "|---|---|---|---|---|"
    if ((${#ROWS[@]})); then
      printf '%s\n' "${ROWS[@]}"
    fi
    echo ""
    echo "Result: ${PRESENT_OK}/${TOTAL} present · ${META_OK}/${TOTAL} resolvable"
    if [[ "$FAILED" -ne 0 ]]; then
      echo ""
      echo "> ❌ Some packages are missing on the repository or unresolvable through metadata."
    fi
    echo ""
  } | tee -a "${GITHUB_STEP_SUMMARY:-/dev/stdout}"

  if [[ "$FAILED" -ne 0 ]]; then
    echo "::error::pulp verification: ${DISTRIB:-?} verification failed (see the table above)"
    return 1
  fi
  echo "[INFO] All ${TOTAL} package(s) verified on ${DISTRIB:-?}"
  return 0
}
