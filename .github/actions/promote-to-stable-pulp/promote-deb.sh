#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=.github/scripts/pulp/manifest.sh
source "$(dirname "$0")/../../scripts/pulp/manifest.sh"
# shellcheck source=.github/scripts/pulp/api.sh
source "$(dirname "$0")/../../scripts/pulp/api.sh"

# an unset org variable is forwarded as an empty string, overriding the default
PULP_URL="${PULP_URL:-https://pulp-api.int.centreon.com}"
PULP_CONTENT_URL="${PULP_CONTENT_URL:-https://packages.int.centreon.com}"
# stable shares its Domain with testing since the domain merge (PULP_STABLE_DOMAIN
# now equals PULP_DOMAIN); the read/write phase switch is kept as a no-op
PULP_DOMAIN="${PULP_DOMAIN:-default}"
PULP_STABLE_DOMAIN="${PULP_STABLE_DOMAIN:-default}"
# switch_pulp_domain overwrites PULP_DOMAIN itself once the write phase
# starts; download_testing_package always needs the original (testing-tier)
# domain, including after the switch, so keep our own copy
TESTING_DOMAIN="$PULP_DOMAIN"

if ! pulp_resource_exists "repositories/deb/apt" "$REPOSITORY_NAME"; then
  echo "::error::Nothing to promote, repository $REPOSITORY_NAME does not exist"
  exit 1
fi

VERSION_HREF=$(pulp deb repository show --name "$REPOSITORY_NAME" | jq -r '.latest_version_href')

# fetch a published index into a file: 0=ok, 2=absent (404), 1=error
fetch_index() {
  local url=$1 out=$2 code
  code=$(content_curl -sSL --retry 3 --retry-delay 5 -o "$out" -w '%{http_code}' "$url") || return 1
  [[ "$code" == "200" ]] && return 0
  [[ "$code" == "404" ]] && return 2
  return 1
}

# collect the sha256 set of every package published in a suite: the served
# dists/ indexes are the source of truth for suite membership (relative_path
# and the release_components api can't be trusted/used here, see deliver-deb.sh).
# A missing Release (404) is an empty suite; any other fetch failure aborts.
suite_sha_file() {
  local base_path=$1 suite=$2 out release_file arches arch pkg_file rc
  out=$(mktemp)
  release_file=$(mktemp)
  fetch_index "$PULP_CONTENT_URL/$base_path/dists/$suite/Release" "$release_file" && rc=0 || rc=$?
  if [[ $rc -eq 2 ]]; then
    echo "$out"
    return 0
  elif [[ $rc -ne 0 ]]; then
    echo "::error::Cannot fetch the $suite Release index; refusing to promote from a partial view." >&2
    return 1
  fi
  arches=$(awk -F': ' '/^Architectures:/ {print $2}' "$release_file")
  for arch in $arches; do
    pkg_file=$(mktemp)
    if ! fetch_index "$PULP_CONTENT_URL/$base_path/dists/$suite/main/binary-$arch/Packages" "$pkg_file"; then
      echo "::error::Cannot fetch the $suite binary-$arch Packages index; refusing to promote from a partial view." >&2
      return 1
    fi
    awk -F': ' '/^SHA256:/ {print $2}' "$pkg_file" >> "$out"
    rm -f "$pkg_file"
  done
  rm -f "$release_file"
  sort -u "$out" -o "$out"
  echo "$out"
}

# resolve the served filename from the testing suite's Packages file by
# sha256 (the published pool layout doesn't match the upload relative_path)
download_testing_package() {
  local sha256=$1 arch=$2 dest=$3 filename
  filename=$(
    content_curl -fsSL --retry 3 --retry-delay 5 "$PULP_CONTENT_URL/${LEGACY_TESTING_BASE_PATH:-$TESTING_DOMAIN/$BASE_PATH}/dists/$TESTING_SUITE/main/binary-$arch/Packages" |
      awk -v sha="$sha256" 'BEGIN { RS = ""; FS = "\n" } index($0, "SHA256: " sha) { for (i = 1; i <= NF; i++) if ($i ~ /^Filename: /) { sub(/^Filename: /, "", $i); print $i; exit } }'
  )
  if [[ -z "$filename" ]]; then
    echo "::error::Cannot locate the published file for sha256 $sha256 in $TESTING_SUITE ($arch)" >&2
    return 1
  fi
  content_curl -fsSL --retry 3 --retry-delay 5 -o "$dest" "$PULP_CONTENT_URL/${LEGACY_TESTING_BASE_PATH:-$TESTING_DOMAIN/$BASE_PATH}/$filename"
}

TESTING_SHAS_FILE=$(suite_sha_file "${LEGACY_TESTING_BASE_PATH:-$TESTING_DOMAIN/$BASE_PATH}" "$TESTING_SUITE")

# paginated: the repository keeps every delivered version across all suites,
# so the module listing can exceed a single page
RESULTS_FILE=$(mktemp)
url="$PULP_URL/$PULP_DOMAIN/api/v3/content/deb/packages/?$(
  printf 'repository_version=%s&pulp_label_select=%s&limit=1000' \
    "$(jq -rn --arg v "$VERSION_HREF" '$v | @uri')" \
    "$(jq -rn --arg v "module=$MODULE_NAME" '$v | @uri')"
)"
while [[ -n "$url" ]]; do
  refresh_pulp_token
  page=$(curl -fsSL -H "Authorization: Bearer $PULP_TOKEN" "$url")
  echo "$page" | jq -c '.results[]' >> "$RESULTS_FILE"
  url=$(echo "$page" | jq -r '.next // empty')
done

# only the LATEST version of each package is promoted (deb has no retention
# mechanism, testing accumulates every build); compare segment by segment
# (numeric as numbers) since a plain string max ranks "0.9" above "0.10"
TESTING_SET_FILE=$(mktemp)
jq -R . "$TESTING_SHAS_FILE" | jq -s 'map({key: ., value: true}) | from_entries' > "$TESTING_SET_FILE"
PACKAGES=$(
  jq -s --slurpfile testing_set "$TESTING_SET_FILE" \
    'def vkey: [scan("[0-9]+|[^0-9]+") | (tonumber? // .)];
     [.[] | select($testing_set[0][.sha256])]
     | group_by(.package, .architecture) | map(max_by(.version | vkey))' \
    "$RESULTS_FILE"
)
rm -f "$RESULTS_FILE" "$TESTING_SHAS_FILE" "$TESTING_SET_FILE"
PACKAGES_COUNT=$(echo "$PACKAGES" | jq 'length')

if [[ "$PACKAGES_COUNT" -eq 0 ]]; then
  echo "::error::Nothing to promote, no package of module $MODULE_NAME found in the $TESTING_SUITE suite of $REPOSITORY_NAME"
  exit 1
fi

echo "[INFO] $PACKAGES_COUNT packages of module $MODULE_NAME found in the $TESTING_SUITE suite of $REPOSITORY_NAME"

if [[ "$STABILITY" != "stable" ]]; then
  echo "[INFO] Dry run, $PACKAGES_COUNT packages would be promoted to $STABLE_SUITE/main"
  exit 0
fi

# everything from here on targets the stable-tier domain
refresh_pulp_token
switch_pulp_domain "$PULP_STABLE_DOMAIN"

if ! pulp_resource_exists "repositories/deb/apt" "$STABLE_REPOSITORY_NAME"; then
  echo "::error::Stable repository $STABLE_REPOSITORY_NAME does not exist. Pulp repositories are provisioned centrally by delivery-tooling create-repos; run create-repos before promoting."
  exit 1
fi
STABLE_REPOSITORY_HREF=$(pulp deb repository show --name "$STABLE_REPOSITORY_NAME" | jq -r '.pulp_href')

# 24.x standard clients use the dedicated legacy repository form
# (apt-standard-24.10-stable/ with a plain-codename suite, provisioned by
# create-repos): mirror every candidate package association into that suite so
# both suites always list the same stable content. Idempotent (rerun safe).
ensure_legacy_suite_associations() {
  [[ -z "${STABLE_LEGACY_SUITE:-}" ]] && return 0
  refresh_pulp_token
  local latest legacy_rc
  latest=$(pulp deb repository show --name "$STABLE_REPOSITORY_NAME" | jq -r '.latest_version_href')
  legacy_rc=$(
    curl -fsSL --retry 3 --retry-delay 5 -H "Authorization: Bearer $PULP_TOKEN" \
      "$PULP_URL/$PULP_DOMAIN/api/v3/content/deb/release_components/?$(
        printf 'repository_version=%s&distribution=%s&component=main&limit=1' \
          "$(jq -rn --arg v "$latest" '$v | @uri')" "$(jq -rn --arg v "$STABLE_LEGACY_SUITE" '$v | @uri')"
      )" | jq -r '.results[0].pulp_href // empty'
  )
  if [[ -z "$legacy_rc" ]]; then
    echo "::error::Cannot resolve the $STABLE_LEGACY_SUITE/main release component (dedicated legacy suite, provisioned by create-repos)"
    return 1
  fi
  echo "[INFO] Mirroring $PACKAGES_COUNT package association(s) into $STABLE_LEGACY_SUITE/main (dedicated legacy suite)"
  local units_file body_file sha href out code body prc n=0
  units_file=$(mktemp)
  while read -r sha; do
    if ((n % 40 == 0)); then refresh_pulp_token; fi
    n=$((n + 1))
    href=$(lookup_deb_content "packages" "--data-urlencode sha256=$sha")
    if [[ -z "$href" ]]; then
      echo "::error::Cannot resolve the promoted package (sha256 $sha) for the $STABLE_LEGACY_SUITE mirror"
      return 1
    fi
    out=$(post_json "$PULP_URL/$PULP_DOMAIN/api/v3/content/deb/package_release_components/" \
      "{\"package\": \"$href\", \"release_component\": \"$legacy_rc\"}") || out=$'\n000'
    code="${out##*$'\n'}"
    body="${out%$'\n'*}"
    prc=""
    if [[ "$code" == 2* ]]; then
      prc=$(echo "$body" | jq -r '.pulp_href // empty' 2>/dev/null) || prc=""
    fi
    if [[ -z "$prc" ]]; then
      # the api answers 500 on a duplicate synchronous create; expected on a rerun
      prc=$(lookup_deb_content "package_release_components" \
        "--data-urlencode package=$href --data-urlencode release_component=$legacy_rc")
    fi
    if [[ -z "$prc" ]]; then
      echo "::error::Legacy suite association failed for sha256 $sha (HTTP $code)"
      return 1
    fi
    printf '%s\n%s\n' "$href" "$prc" >> "$units_file"
  done < <(echo "$PACKAGES" | jq -r '.[].sha256')
  body_file=$(mktemp)
  jq -R . "$units_file" | jq -cs '{add_content_units: ([.[] | select(. != "")] | unique)}' > "$body_file"
  rm -f "$units_file"
  local task rc
  for _ in 1 2 3; do
    task=$(start_modify_task "$PULP_URL${STABLE_REPOSITORY_HREF}modify/" "$body_file")
    wait_task_race "$task" && rc=0 || rc=$?
    if [[ $rc -eq 0 ]]; then
      rm -f "$body_file"
      return 0
    fi
  done
  echo "::error::Cannot add the $STABLE_LEGACY_SUITE mirror associations to $STABLE_REPOSITORY_NAME"
  return 1
}

# "already promoted" is decided against the stable repository's OWN version
# (it's always dedicated, never shared, so it only ever receives stable content)
STABLE_SHAS_FILE=$(mktemp)
STABLE_VERSION_HREF=$(pulp deb repository show --name "$STABLE_REPOSITORY_NAME" | jq -r '.latest_version_href')
url="$PULP_URL/$PULP_DOMAIN/api/v3/content/deb/packages/?$(
  printf 'repository_version=%s&fields=sha256&limit=1000' \
    "$(jq -rn --arg v "$STABLE_VERSION_HREF" '$v | @uri')"
)"
while [[ -n "$url" ]]; do
  refresh_pulp_token
  page=$(curl -fsSL --retry 3 --retry-delay 5 -H "Authorization: Bearer $PULP_TOKEN" "$url")
  echo "$page" | jq -r '.results[].sha256' >> "$STABLE_SHAS_FILE"
  url=$(echo "$page" | jq -r '.next // empty')
done
sort -u "$STABLE_SHAS_FILE" -o "$STABLE_SHAS_FILE"

mkdir -p promoted-packages

# mirrors deliver-deb.sh's own PULP_LABELS, but this run's own git context
PULP_LABELS=$(jq -cn \
  --arg mod        "$MODULE_NAME" \
  --arg git_commit "${GITHUB_SHA:-}" \
  --arg git_ref    "${GITHUB_REF:-}" \
  --arg run_id     "${GITHUB_RUN_ID:-}" \
  --arg actor      "${GITHUB_ACTOR:-}" \
  --arg workflow   "${GITHUB_WORKFLOW:-}" \
  '{"module": $mod, "git_commit": $git_commit, "git_ref": $git_ref, "github_run_id": $run_id, "github_actor": $actor, "github_workflow": $workflow}')

# emit the href of a matching stable-domain deb content unit, empty if absent.
# Retried: the api has been observed answering an empty page for content
# committed seconds earlier (stale read)
lookup_deb_content() {
  local endpoint=$1 query=$2 out attempt
  for attempt in 1 2 3 4 5; do
    out=$(curl -fsSL --retry 3 --retry-delay 5 -H "Authorization: Bearer $PULP_TOKEN" -G \
      --data-urlencode "limit=1" \
      $query \
      "$PULP_URL/$PULP_DOMAIN/api/v3/content/deb/$endpoint/" | jq -r '.results[0].pulp_href // empty') || out=""
    if [[ -n "$out" ]]; then
      echo "$out"
      return 0
    fi
    sleep $((attempt * 3))
    refresh_pulp_token
  done
}

# emit the release-component hrefs a package is associated with
lookup_prcs() {
  local package_href=$1
  curl -fsSL --retry 3 --retry-delay 5 -H "Authorization: Bearer $PULP_TOKEN" -G \
    --data-urlencode "package=$package_href" \
    --data-urlencode "limit=100" \
    "$PULP_URL/$PULP_DOMAIN/api/v3/content/deb/package_release_components/" \
    | jq -r '.results[].release_component'
}

# candidates already published in the stable suite need no new association;
# when EVERYTHING already reached stable (a rerun after the modify), only the
# publication may be missing: republish and stop.
UNPROMOTED_HREFS=()
while read -r PACKAGE; do
  sha=$(echo "$PACKAGE" | jq -r '.sha256')
  if ! grep -qxF "$sha" "$STABLE_SHAS_FILE"; then
    UNPROMOTED_HREFS+=("$(echo "$PACKAGE" | jq -r '.pulp_href')")
  fi
done < <(echo "$PACKAGES" | jq -c '.[]')
rm -f "$STABLE_SHAS_FILE"
if ((${#UNPROMOTED_HREFS[@]} == 0)); then
  echo "[INFO] All $PACKAGES_COUNT package(s) are already promoted to $STABLE_SUITE; republishing only"
  while read -r PACKAGE; do
    manifest_add "$(echo "$PACKAGE" | jq -c \
      --arg repository "$STABLE_REPOSITORY_NAME" --arg base_path "${LEGACY_STABLE_BASE_PATH:-$PULP_STABLE_DOMAIN/$STABLE_BASE_PATH}" \
      --arg suite "$STABLE_SUITE" \
      '{filename: (.relative_path | sub(".*/"; "")), name: .package, version, arch: .architecture, sha256, repository: $repository, base_path: $base_path, suite: $suite, relative_path}')"
  done < <(echo "$PACKAGES" | jq -c '.[]')
  ensure_legacy_suite_associations
  create_publication deb "$STABLE_REPOSITORY_NAME" --structured
  echo "::notice::Packages are available with: deb $PULP_CONTENT_URL/${LEGACY_STABLE_BASE_PATH:-$PULP_STABLE_DOMAIN/$STABLE_BASE_PATH}/ $STABLE_SUITE main"
  manifest_write "$MODULE_NAME" "${DISTRIB:-}" "deb" "$STABILITY" "promote" "$PULP_CONTENT_URL"
  exit 0
fi

# batched promote, mirroring the batched delivery. Testing and stable share
# their domain (and content) since the domain merge: the batch below associates
# the testing package hrefs directly, no re-download/re-upload. Only the FIRST
# package of each arch goes through the legacy upload path, to establish the
# release component and deduce its href (see deliver-deb.sh; listing release
# components requires admin rights).
declare -A ARCH_SEEN=()
LEGACY_PACKAGES=()
BATCH_PACKAGES=()
while read -r PACKAGE; do
  ARCH=$(echo "$PACKAGE" | jq -r '.architecture')
  if [[ -z "${ARCH_SEEN[$ARCH]+set}" ]]; then
    ARCH_SEEN[$ARCH]=1
    LEGACY_PACKAGES+=("$PACKAGE")
  else
    BATCH_PACKAGES+=("$PACKAGE")
  fi
done < <(echo "$PACKAGES" | jq -c '.[]')

# capture the reference package's pre-upload stable associations (if it
# already exists there, e.g. a rerun) so the new one stands out as the diff
refresh_pulp_token
LEGACY_REF_SHA256=$(echo "${LEGACY_PACKAGES[0]}" | jq -r '.sha256')
LEGACY_REF_BEFORE_HREF=$(lookup_deb_content "packages" "--data-urlencode sha256=$LEGACY_REF_SHA256")
LEGACY_REF_BEFORE=""
[[ -n "$LEGACY_REF_BEFORE_HREF" ]] && LEGACY_REF_BEFORE=$(lookup_prcs "$LEGACY_REF_BEFORE_HREF" | sort)

for PACKAGE in "${LEGACY_PACKAGES[@]}"; do
  RELATIVE_PATH=$(echo "$PACKAGE" | jq -r '.relative_path')
  SHA256=$(echo "$PACKAGE" | jq -r '.sha256')
  ARCH=$(echo "$PACKAGE" | jq -r '.architecture')
  FILE_NAME=$(basename "$RELATIVE_PATH")
  FILE="promoted-packages/$FILE_NAME"

  echo "[INFO] Downloading $FILE_NAME from $TESTING_SUITE"
  download_testing_package "$SHA256" "$ARCH" "$FILE"

  # same relative_path into stable: pulp reuses existing content and adds the
  # stable suite association, creating the ReleaseComponent/ReleaseArchitecture
  # retried: the legacy path creates a repository version and can lose the race
  for legacy_attempt in 1 2 3; do
    echo "[INFO] Promoting $FILE_NAME to $STABLE_SUITE/main [legacy path, attempt $legacy_attempt]"
    TASK_HREF=$(
      pulp_upload \
        -F "file=@\"$FILE\"" \
        -F "relative_path=$RELATIVE_PATH" \
        -F "distribution=$STABLE_SUITE" \
        -F "component=main" \
        -F "repository=$STABLE_REPOSITORY_HREF" \
        -F "pulp_labels=$PULP_LABELS" \
        "$PULP_URL/$PULP_DOMAIN/api/v3/content/deb/packages/"
    )
    wait_task_race "$TASK_HREF" && rc=0 || rc=$?
    if [[ $rc -eq 0 ]]; then
      break
    elif [[ $rc -eq 2 && $legacy_attempt -lt 3 ]]; then
      echo "[WARN] Legacy promotion of $FILE_NAME lost the repository-version race, retrying"
      sleep $((legacy_attempt * 15))
    else
      echo "::error::Legacy promotion of $FILE_NAME failed"
      exit 1
    fi
  done
done

if ((${#BATCH_PACKAGES[@]} > 0)); then
  # the release component is the association the legacy re-upload just added
  # to the reference package (diffed against its pre-upload set captured above)
  refresh_pulp_token
  LEGACY_REF_STABLE_HREF=$(lookup_deb_content "packages" "--data-urlencode sha256=$LEGACY_REF_SHA256")
  if [[ -z "$LEGACY_REF_STABLE_HREF" ]]; then
    echo "::error::Cannot resolve the promoted reference package (sha256 $LEGACY_REF_SHA256) in the stable domain"
    exit 1
  fi
  LEGACY_REF_AFTER=$(lookup_prcs "$LEGACY_REF_STABLE_HREF" | sort)
  STABLE_RC_SET=$(comm -13 <(echo "$LEGACY_REF_BEFORE") <(echo "$LEGACY_REF_AFTER") | grep . || true)
  if [[ $(echo "$STABLE_RC_SET" | grep -c .) -ne 1 ]]; then
    refresh_pulp_token
    STABLE_LATEST=$(pulp deb repository show --name "$STABLE_REPOSITORY_NAME" | jq -r '.latest_version_href')
    STABLE_RC_SET=$(
      curl -fsSL --retry 3 --retry-delay 5 -H "Authorization: Bearer $PULP_TOKEN" \
        "$PULP_URL/$PULP_DOMAIN/api/v3/content/deb/release_components/?$(
          printf 'repository_version=%s&distribution=%s&component=main&limit=1' \
            "$(jq -rn --arg v "$STABLE_LATEST" '$v | @uri')" "$(jq -rn --arg v "$STABLE_SUITE" '$v | @uri')"
        )" | jq -r '.results[0].pulp_href // empty'
    )
  fi
  STABLE_RC=$(echo "$STABLE_RC_SET" | grep . | head -1)
  if [[ -z "$STABLE_RC" ]]; then
    # a promotion interrupted after its repository modify only misses the
    # publication: republish and re-check every candidate before giving up
    echo "[WARN] Cannot deduce the $STABLE_SUITE/main release component (got: ${STABLE_RC_SET:-none}); republishing to check for an interrupted promotion"
    ensure_legacy_suite_associations
    create_publication deb "$STABLE_REPOSITORY_NAME" --structured
    RECHECK_SHAS_FILE=$(suite_sha_file "${LEGACY_STABLE_BASE_PATH:-$PULP_STABLE_DOMAIN/$STABLE_BASE_PATH}" "$STABLE_SUITE")
    MISSING_COUNT=0
    while read -r sha; do
      grep -qxF "$sha" "$RECHECK_SHAS_FILE" || MISSING_COUNT=$((MISSING_COUNT + 1))
    done < <(echo "$PACKAGES" | jq -r '.[].sha256')
    rm -f "$RECHECK_SHAS_FILE"
    if ((MISSING_COUNT == 0)); then
      echo "[INFO] Every candidate package is published in $STABLE_SUITE; the interrupted promotion only missed the publication"
      while read -r PACKAGE; do
        manifest_add "$(echo "$PACKAGE" | jq -c \
          --arg repository "$STABLE_REPOSITORY_NAME" --arg base_path "${LEGACY_STABLE_BASE_PATH:-$PULP_STABLE_DOMAIN/$STABLE_BASE_PATH}" \
          --arg suite "$STABLE_SUITE" \
          '{filename: (.relative_path | sub(".*/"; "")), name: .package, version, arch: .architecture, sha256, repository: $repository, base_path: $base_path, suite: $suite, relative_path}')"
      done < <(echo "$PACKAGES" | jq -c '.[]')
      echo "::notice::Packages are available with: deb $PULP_CONTENT_URL/${LEGACY_STABLE_BASE_PATH:-$PULP_STABLE_DOMAIN/$STABLE_BASE_PATH}/ $STABLE_SUITE main"
      manifest_write "$MODULE_NAME" "${DISTRIB:-}" "deb" "$STABILITY" "promote" "$PULP_CONTENT_URL"
      exit 0
    fi
    echo "::error::Cannot deduce the $STABLE_SUITE/main release component (got: ${STABLE_RC_SET:-none}) and $MISSING_COUNT candidate package(s) are missing from the published $STABLE_SUITE suite. A previous promotion likely left the suite associations without the repository content; deliver a rebuilt (fresh) build or add the packages to the stable repository manually."
    exit 1
  fi
  echo "[INFO] Release component of $STABLE_SUITE/main: $STABLE_RC"

  # remaining packages: the testing content hrefs are associated with the
  # stable release component directly (same domain, shared content); the
  # packages keep their delivery-time labels
  PACKAGE_HREFS=()
  for PACKAGE in "${BATCH_PACKAGES[@]}"; do
    PACKAGE_HREFS+=("$(echo "$PACKAGE" | jq -r '.pulp_href')")
  done

  # package_release_components create is synchronous (201 with the unit, no
  # task); a failed create (already existing on a job re-run) falls back to a lookup
  echo "[INFO] Associating ${#PACKAGE_HREFS[@]} package(s) with $STABLE_SUITE/main"
  MAX_PARALLEL=8
  PRC_DIR=$(mktemp -d)
  for i in "${!PACKAGE_HREFS[@]}"; do
    if ((i % 40 == 0)); then
      refresh_pulp_token
    fi
    (
      refresh_pulp_token
      package_href="${PACKAGE_HREFS[$i]}"
      out=$(post_json "$PULP_URL/$PULP_DOMAIN/api/v3/content/deb/package_release_components/" \
        "{\"package\": \"$package_href\", \"release_component\": \"$STABLE_RC\"}") || out=$'\n000'
      code="${out##*$'\n'}"
      body="${out%$'\n'*}"
      href=""
      if [[ "$code" == 2* ]]; then
        # tolerate a non-json body (gateway error page behind a 2xx)
        href=$(echo "$body" | jq -r '.pulp_href // empty' 2>/dev/null) || href=""
      fi
      if [[ -z "$href" ]]; then
        # api answers 500 on a duplicate synchronous create; expected on a rerun
        echo "[INFO] $(echo "${BATCH_PACKAGES[$i]}" | jq -r '.package'): stable association create answered HTTP $code, falling back to the lookup (expected on a rerun)"
        href=$(lookup_deb_content "package_release_components" \
          "--data-urlencode package=$package_href --data-urlencode release_component=$STABLE_RC")
      fi
      printf '%s\n%s' "$package_href" "$href" > "$PRC_DIR/$i.pair"
    ) &
    while (($(jobs -rp | wc -l) >= MAX_PARALLEL)); do
      wait -n || true
    done
  done
  wait || true

  ADD_UNITS_FILE=$(mktemp)
  for i in "${!BATCH_PACKAGES[@]}"; do
    if [[ ! -s "$PRC_DIR/$i.pair" ]] || [[ -z "$(sed -n '2p' "$PRC_DIR/$i.pair")" ]]; then
      echo "::error::Stable suite association failed for package $(echo "${BATCH_PACKAGES[$i]}" | jq -r '.package') (see the worker error above)"
      exit 1
    fi
    cat "$PRC_DIR/$i.pair" >> "$ADD_UNITS_FILE"
    echo >> "$ADD_UNITS_FILE"
  done
  rm -rf "$PRC_DIR"

  echo "[INFO] Adding ${#BATCH_PACKAGES[@]} package(s) and their suite associations to $STABLE_REPOSITORY_NAME in a single task"
  refresh_pulp_token
  # body through a file: thousands of hrefs exceed the argv limit
  ADD_BODY_FILE=$(mktemp)
  jq -R . "$ADD_UNITS_FILE" | jq -cs '{add_content_units: [.[] | select(. != "")]}' > "$ADD_BODY_FILE"
  rm -f "$ADD_UNITS_FILE"
  # retried like the legacy uploads: same repository-version race
  for modify_attempt in 1 2 3; do
    MODIFY_TASK=$(start_modify_task "$PULP_URL${STABLE_REPOSITORY_HREF}modify/" "$ADD_BODY_FILE")
    wait_task_race "$MODIFY_TASK" && rc=0 || rc=$?
    if [[ $rc -eq 0 ]]; then
      break
    elif [[ $rc -eq 2 && $modify_attempt -lt 3 ]]; then
      echo "[WARN] Stable repository modify lost the repository-version race, retrying"
      sleep $((modify_attempt * 15))
    else
      echo "::error::Stable repository modify failed"
      exit 1
    fi
  done
fi

# record the promoted packages (with their stable suite coordinates) so the
# verification step verifies exactly this set against the stable suite
while read -r PACKAGE; do
  manifest_add "$(echo "$PACKAGE" | jq -c \
    --arg repository "$STABLE_REPOSITORY_NAME" --arg base_path "${LEGACY_STABLE_BASE_PATH:-$PULP_STABLE_DOMAIN/$STABLE_BASE_PATH}" \
    --arg suite "$STABLE_SUITE" \
    '{filename: (.relative_path | sub(".*/"; "")), name: .package, version, arch: .architecture, sha256, repository: $repository, base_path: $base_path, suite: $suite, relative_path}')"
done < <(echo "$PACKAGES" | jq -c '.[]')

ensure_legacy_suite_associations
echo "[INFO] Publishing repository $STABLE_REPOSITORY_NAME"
create_publication deb "$STABLE_REPOSITORY_NAME" --structured

echo "::notice::Packages are available with: deb $PULP_CONTENT_URL/${LEGACY_STABLE_BASE_PATH:-$PULP_STABLE_DOMAIN/$STABLE_BASE_PATH}/ $STABLE_SUITE main"

manifest_write "$MODULE_NAME" "${DISTRIB:-}" "deb" "$STABILITY" "promote" "$PULP_CONTENT_URL"
