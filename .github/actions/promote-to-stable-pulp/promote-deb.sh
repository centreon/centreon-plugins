#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=.github/scripts/pulp/manifest.sh
source "$(dirname "$0")/../../scripts/pulp/manifest.sh"
# shellcheck source=.github/scripts/pulp/api.sh
source "$(dirname "$0")/../../scripts/pulp/api.sh"

# use the org-variable values, falling back to the defaults when passed empty
# (an unset org variable is forwarded as an empty string, overriding the default)
PULP_URL="${PULP_URL:-https://pulp-api.apps.centreon.com}"
PULP_CONTENT_URL="${PULP_CONTENT_URL:-https://packages.apps.centreon.com}"

# the stable packages may live in a DEDICATED repository (deb plugins:
# apt-plugins-stable/ubuntu-plugins-stable with plain-codename suites, the
# artifactory-compatible client layout); default to the source repository
# for the families whose stable suite it hosts.
STABLE_REPOSITORY_NAME="${STABLE_REPOSITORY_NAME:-$REPOSITORY_NAME}"
STABLE_BASE_PATH="${STABLE_BASE_PATH:-$BASE_PATH}"

if ! pulp deb repository show --name "$REPOSITORY_NAME" >/dev/null 2>&1; then
  echo "::error::Nothing to promote, repository $REPOSITORY_NAME does not exist"
  exit 1
fi

if ! pulp deb repository show --name "$STABLE_REPOSITORY_NAME" >/dev/null 2>&1; then
  echo "::error::Stable repository $STABLE_REPOSITORY_NAME does not exist. Pulp repositories are provisioned centrally by delivery-tooling create-repos; run create-repos before promoting."
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

# collect the sha256 set of every package published in a suite. The served
# dists/ indexes are the source of truth for suite membership: the packages'
# relative_path cannot be trusted for that (content reused across suites
# keeps its original upload path) and the release_components api is not
# listable by the OIDC ci-user. A missing Release (404) is an empty suite;
# any other fetch failure aborts, a partial set must not drive a promotion.
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

TESTING_SHAS_FILE=$(suite_sha_file "$BASE_PATH" "$TESTING_SUITE")

# "already promoted" is decided against the stable repository VERSION when a
# dedicated stable repository is used (it only ever receives stable content):
# a promotion whose publication failed then reruns as a plain republish. With
# a shared repository the version cannot discriminate suites, so membership
# stays based on the published stable index.
if [[ "$STABLE_REPOSITORY_NAME" != "$REPOSITORY_NAME" ]]; then
  STABLE_SHAS_FILE=$(mktemp)
  STABLE_VERSION_HREF=$(pulp deb repository show --name "$STABLE_REPOSITORY_NAME" | jq -r '.latest_version_href')
  url="$PULP_URL/api/v3/content/deb/packages/?$(
    printf 'repository_version=%s&fields=sha256&limit=1000' \
      "$(jq -rn --arg v "$STABLE_VERSION_HREF" '$v | @uri')"
  )"
  while [[ -n "$url" ]]; do
    refresh_pulp_token
    page=$(curl -fsSL --retry 3 --retry-delay 5 -H "Authorization: Github $PULP_TOKEN" "$url")
    echo "$page" | jq -r '.results[].sha256' >> "$STABLE_SHAS_FILE"
    url=$(echo "$page" | jq -r '.next // empty')
  done
  sort -u "$STABLE_SHAS_FILE" -o "$STABLE_SHAS_FILE"
else
  STABLE_SHAS_FILE=$(suite_sha_file "$STABLE_BASE_PATH" "$STABLE_SUITE")
fi

# packages of the module are identified by the label set at delivery time.
# Paginated: the shared repository keeps every delivered version across all
# suites, so the module listing exceeds a single page.
RESULTS_FILE=$(mktemp)
url="$PULP_URL/api/v3/content/deb/packages/?$(
  printf 'repository_version=%s&pulp_label_select=%s&limit=1000' \
    "$(jq -rn --arg v "$VERSION_HREF" '$v | @uri')" \
    "$(jq -rn --arg v "module=$MODULE_NAME" '$v | @uri')"
)"
while [[ -n "$url" ]]; do
  refresh_pulp_token
  page=$(curl -fsSL -H "Authorization: Github $PULP_TOKEN" "$url")
  echo "$page" | jq -c '.results[]' >> "$RESULTS_FILE"
  url=$(echo "$page" | jq -r '.next // empty')
done

# only the LATEST version of each package is promoted: the testing suite
# accumulates every delivered build (deb has no retention mechanism).
# Versions are compared segment by segment (numeric segments as numbers): a
# plain string max would rank "0.9" above "0.10", which bites the
# semver-like versions of some modules. Pipeline-built versions carry no
# epoch or tilde.
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

STABLE_REPOSITORY_HREF=$(pulp deb repository show --name "$STABLE_REPOSITORY_NAME" | jq -r '.pulp_href')

mkdir -p promoted-packages

# module label, built with jq (safe escaping) — consistent with the delivery scripts
PULP_LABELS=$(jq -cn --arg mod "$MODULE_NAME" '{"module": $mod}')

# emit the release-component hrefs a package is associated with
lookup_prcs() {
  local package_href=$1
  curl -fsSL --retry 3 --retry-delay 5 -H "Authorization: Github $PULP_TOKEN" -G \
    --data-urlencode "package=$package_href" \
    --data-urlencode "limit=100" \
    "$PULP_URL/api/v3/content/deb/package_release_components/" \
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
      --arg repository "$STABLE_REPOSITORY_NAME" --arg base_path "$STABLE_BASE_PATH" \
      --arg suite "$STABLE_SUITE" \
      '{filename: (.relative_path | sub(".*/"; "")), name: .package, version, arch: .architecture, sha256, repository: $repository, base_path: $base_path, suite: $suite, relative_path}')"
  done < <(echo "$PACKAGES" | jq -c '.[]')
  create_publication deb "$STABLE_REPOSITORY_NAME" --structured
  echo "::notice::Packages are available with: deb $PULP_CONTENT_URL/$STABLE_BASE_PATH/ $STABLE_SUITE main"
  manifest_write "$MODULE_NAME" "${DISTRIB:-}" "deb" "$STABILITY" "promote" "$PULP_CONTENT_URL"
  exit 0
fi

# batched promote, mirroring the batched delivery: the packages already exist
# as content units in the repository (testing suite), so promoting is only a
# matter of stable suite associations. The FIRST package of each architecture
# is promoted through the legacy re-upload path - it get_or_creates the stable
# ReleaseComponent and ReleaseArchitecture, which the ci user cannot create
# nor list directly - then the stable release-component href is deduced from
# its associations, every other association is created synchronously, and one
# modify adds the whole batch to the repository.
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

# the stable release component is deduced from the association the legacy
# re-upload of the FIRST reference creates: capture its association set
# before the upload so the new one stands out as the difference.
refresh_pulp_token
LEGACY_REF_HREF=$(echo "${LEGACY_PACKAGES[0]}" | jq -r '.pulp_href')
LEGACY_REF_BEFORE=$(lookup_prcs "$LEGACY_REF_HREF" | sort)

for PACKAGE in "${LEGACY_PACKAGES[@]}"; do
  RELATIVE_PATH=$(echo "$PACKAGE" | jq -r '.relative_path')
  SHA256=$(echo "$PACKAGE" | jq -r '.sha256')
  ARCH=$(echo "$PACKAGE" | jq -r '.architecture')
  FILE_NAME=$(basename "$RELATIVE_PATH")
  FILE="promoted-packages/$FILE_NAME"

  # the structured publication serves packages under the canonical debian pool
  # layout, not their upload relative_path, so resolve the published location
  # from the testing suite Packages indexed by checksum to download the file
  FILENAME=$(
    content_curl -fsSL --retry 3 --retry-delay 5 "$PULP_CONTENT_URL/$BASE_PATH/dists/$TESTING_SUITE/main/binary-$ARCH/Packages" |
      awk -v sha="$SHA256" 'BEGIN { RS = ""; FS = "\n" } index($0, "SHA256: " sha) { for (i = 1; i <= NF; i++) if ($i ~ /^Filename: /) { sub(/^Filename: /, "", $i); print $i } }'
  )
  if [[ -z "$FILENAME" ]]; then
    echo "::error::Cannot locate the published file of $FILE_NAME (sha256 $SHA256) in $TESTING_SUITE"
    exit 1
  fi

  echo "[INFO] Downloading $PULP_CONTENT_URL/$BASE_PATH/$FILENAME"
  content_curl -fsSL --retry 3 --retry-delay 5 -o "$FILE" "$PULP_CONTENT_URL/$BASE_PATH/$FILENAME"

  # re-upload the same bytes with the SAME relative_path: pulp reuses the
  # existing content unit and only adds the stable suite association,
  # creating the stable ReleaseComponent/ReleaseArchitecture on the way
  echo "[INFO] Promoting $FILE_NAME to $STABLE_SUITE/main [legacy path]"
  TASK_HREF=$(
    pulp_upload \
      -F "file=@\"$FILE\"" \
      -F "relative_path=$RELATIVE_PATH" \
      -F "distribution=$STABLE_SUITE" \
      -F "component=main" \
      -F "repository=$STABLE_REPOSITORY_HREF" \
      -F "pulp_labels=$PULP_LABELS" \
      "$PULP_URL/api/v3/content/deb/packages/"
  )
  wait_task "$TASK_HREF"
done

if ((${#BATCH_PACKAGES[@]} > 0)); then
  # the stable release component is the association the legacy re-upload just
  # added to the reference package. On a rerun the association pre-exists and
  # the difference is empty: the reference then carries every suite it belongs
  # to (stable, testing, possibly unstable for reused content), and the
  # stable one is isolated by subtracting the associations of not-yet-promoted
  # candidates - those belong to every suite of the reference EXCEPT stable.
  refresh_pulp_token
  LEGACY_REF_AFTER=$(lookup_prcs "$LEGACY_REF_HREF" | sort)
  STABLE_RC_SET=$(comm -13 <(echo "$LEGACY_REF_BEFORE") <(echo "$LEGACY_REF_AFTER") | grep . || true)
  if [[ $(echo "$STABLE_RC_SET" | grep -c .) -ne 1 ]]; then
    STABLE_RC_SET=$(echo "$LEGACY_REF_AFTER" | grep . || true)
    for u_href in "${UNPROMOTED_HREFS[@]}"; do
      [[ "$u_href" == "$LEGACY_REF_HREF" ]] && continue
      [[ $(echo "$STABLE_RC_SET" | grep -c .) -le 1 ]] && break
      u_prcs=$(lookup_prcs "$u_href" | sort)
      STABLE_RC_SET=$(comm -23 <(echo "$STABLE_RC_SET") <(echo "$u_prcs") | grep . || true)
    done
  fi
  STABLE_RC=$(echo "$STABLE_RC_SET" | grep . | head -1)
  if [[ (-z "$STABLE_RC" || $(echo "$STABLE_RC_SET" | grep -c .) -ne 1) && "$STABLE_REPOSITORY_NAME" != "$REPOSITORY_NAME" ]]; then
    # dedicated stable repository: it only ever receives stable suite
    # associations, so any association it already holds points to the stable
    # release component. Covers reruns of a promotion interrupted between the
    # association creation and the repository modify, where every
    # before/after diff above is empty.
    refresh_pulp_token
    STABLE_LATEST=$(pulp deb repository show --name "$STABLE_REPOSITORY_NAME" | jq -r '.latest_version_href')
    STABLE_RC=$(
      curl -fsSL --retry 3 --retry-delay 5 -H "Authorization: Github $PULP_TOKEN" \
        "$PULP_URL/api/v3/content/deb/package_release_components/?$(
          printf 'repository_version=%s&limit=1' "$(jq -rn --arg v "$STABLE_LATEST" '$v | @uri')"
        )" | jq -r '.results[0].release_component // empty'
    )
    [[ -n "$STABLE_RC" ]] && STABLE_RC_SET="$STABLE_RC"
  fi
  if [[ -z "$STABLE_RC" || $(echo "$STABLE_RC_SET" | grep -c .) -ne 1 ]]; then
    # a promotion interrupted after its repository modify only misses the
    # publication: republish and re-check every candidate before giving up
    echo "[WARN] Cannot deduce the $STABLE_SUITE/main release component (got: ${STABLE_RC_SET:-none}); republishing to check for an interrupted promotion"
    create_publication deb "$STABLE_REPOSITORY_NAME" --structured
    RECHECK_SHAS_FILE=$(suite_sha_file "$STABLE_BASE_PATH" "$STABLE_SUITE")
    MISSING_COUNT=0
    while read -r sha; do
      grep -qxF "$sha" "$RECHECK_SHAS_FILE" || MISSING_COUNT=$((MISSING_COUNT + 1))
    done < <(echo "$PACKAGES" | jq -r '.[].sha256')
    rm -f "$RECHECK_SHAS_FILE"
    if ((MISSING_COUNT == 0)); then
      echo "[INFO] Every candidate package is published in $STABLE_SUITE; the interrupted promotion only missed the publication"
      while read -r PACKAGE; do
        manifest_add "$(echo "$PACKAGE" | jq -c \
          --arg repository "$STABLE_REPOSITORY_NAME" --arg base_path "$STABLE_BASE_PATH" \
          --arg suite "$STABLE_SUITE" \
          '{filename: (.relative_path | sub(".*/"; "")), name: .package, version, arch: .architecture, sha256, repository: $repository, base_path: $base_path, suite: $suite, relative_path}')"
      done < <(echo "$PACKAGES" | jq -c '.[]')
      echo "::notice::Packages are available with: deb $PULP_CONTENT_URL/$STABLE_BASE_PATH/ $STABLE_SUITE main"
      manifest_write "$MODULE_NAME" "${DISTRIB:-}" "deb" "$STABILITY" "promote" "$PULP_CONTENT_URL"
      exit 0
    fi
    echo "::error::Cannot deduce the $STABLE_SUITE/main release component (got: ${STABLE_RC_SET:-none}) and $MISSING_COUNT candidate package(s) are missing from the published $STABLE_SUITE suite. A previous promotion likely left the suite associations without the repository content; deliver a rebuilt (fresh) build or add the packages to the stable repository manually."
    exit 1
  fi
  echo "[INFO] Release component of $STABLE_SUITE/main: $STABLE_RC"

  # create the stable suite associations: synchronous creates (201 with the
  # unit, no task), parallelized; a failed create (existing association on a
  # re-run) falls back to a lookup
  echo "[INFO] Associating ${#BATCH_PACKAGES[@]} package(s) with $STABLE_SUITE/main"
  PRC_DIR=$(mktemp -d)
  MAX_PARALLEL=8
  for i in "${!BATCH_PACKAGES[@]}"; do
    if ((i % 40 == 0)); then
      refresh_pulp_token
    fi
    (
      refresh_pulp_token
      package_href=$(echo "${BATCH_PACKAGES[$i]}" | jq -r '.pulp_href')
      response=$(
        curl -fsSL --retry 3 --retry-delay 5 -H "Authorization: Github $PULP_TOKEN" \
          -X POST -H "Content-Type: application/json" \
          -d "{\"package\": \"$package_href\", \"release_component\": \"$STABLE_RC\"}" \
          "$PULP_URL/api/v3/content/deb/package_release_components/"
      ) || response=""
      href=$(echo "$response" | jq -r '.pulp_href // empty')
      if [[ -z "$href" ]]; then
        href=$(
          curl -fsSL -H "Authorization: Github $PULP_TOKEN" -G \
            --data-urlencode "package=$package_href" \
            --data-urlencode "release_component=$STABLE_RC" \
            --data-urlencode "limit=1" \
            "$PULP_URL/api/v3/content/deb/package_release_components/" \
            | jq -r '.results[0].pulp_href // empty'
        )
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
  MODIFY_TASK=$(start_modify_task "$PULP_URL${STABLE_REPOSITORY_HREF}modify/" "$ADD_BODY_FILE")
  wait_task "$MODIFY_TASK"
fi

# record the promoted packages (with their stable suite coordinates) so the
# verification step verifies exactly this set against the stable suite
while read -r PACKAGE; do
  manifest_add "$(echo "$PACKAGE" | jq -c \
    --arg repository "$STABLE_REPOSITORY_NAME" --arg base_path "$STABLE_BASE_PATH" \
    --arg suite "$STABLE_SUITE" \
    '{filename: (.relative_path | sub(".*/"; "")), name: .package, version, arch: .architecture, sha256, repository: $repository, base_path: $base_path, suite: $suite, relative_path}')"
done < <(echo "$PACKAGES" | jq -c '.[]')

echo "[INFO] Publishing repository $STABLE_REPOSITORY_NAME"
create_publication deb "$STABLE_REPOSITORY_NAME" --structured

echo "::notice::Packages are available with: deb $PULP_CONTENT_URL/$STABLE_BASE_PATH/ $STABLE_SUITE main"

manifest_write "$MODULE_NAME" "${DISTRIB:-}" "deb" "$STABILITY" "promote" "$PULP_CONTENT_URL"
