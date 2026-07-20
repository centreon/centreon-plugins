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

if ! pulp deb repository show --name "$REPOSITORY_NAME" >/dev/null 2>&1; then
  echo "::error::Nothing to promote, repository $REPOSITORY_NAME does not exist"
  exit 1
fi

VERSION_HREF=$(pulp deb repository show --name "$REPOSITORY_NAME" | jq -r '.latest_version_href')

# packages of the module are identified by the label set at delivery time,
# the testing pool path scopes the stability and the package distrib name
# scopes the distribution as the apt repository holds all the suites.
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
# accumulates every delivered build (deb has no retention mechanism), and
# our version schemes embed a monotonic date/timestamp so the plain string
# max is the newest build
PACKAGES=$(
  jq -s --arg testing_path "$TESTING_POOL_PATH/" --arg distrib_name "$PACKAGE_DISTRIB_NAME" \
    '[.[] | select((.relative_path | startswith($testing_path)) and (.relative_path | contains($distrib_name)))]
     | group_by(.package, .architecture) | map(max_by(.version))' \
    "$RESULTS_FILE"
)
rm -f "$RESULTS_FILE"
PACKAGES_COUNT=$(echo "$PACKAGES" | jq 'length')

if [[ "$PACKAGES_COUNT" -eq 0 ]]; then
  echo "::error::Nothing to promote, no package of module $MODULE_NAME found in $REPOSITORY_NAME ($TESTING_POOL_PATH/)"
  exit 1
fi

echo "[INFO] $PACKAGES_COUNT packages of module $MODULE_NAME found in $REPOSITORY_NAME ($TESTING_POOL_PATH/)"

if [[ "$STABILITY" != "stable" ]]; then
  echo "[INFO] Dry run, $PACKAGES_COUNT packages would be promoted to $STABLE_SUITE/main"
  exit 0
fi

REPOSITORY_HREF=$(pulp deb repository show --name "$REPOSITORY_NAME" | jq -r '.pulp_href')

mkdir -p promoted-packages

# module label, built with jq (safe escaping) — consistent with the delivery scripts
PULP_LABELS=$(jq -cn --arg mod "$MODULE_NAME" '{"module": $mod}')

lookup_prcs() {
  # emit the release_component hrefs of a package's suite associations
  local package_href=$1
  curl -fsSL -H "Authorization: Github $PULP_TOKEN" -G \
    --data-urlencode "package=$package_href" \
    --data-urlencode "limit=100" \
    "$PULP_URL/api/v3/content/deb/package_release_components/" \
    | jq -r '.results[].release_component'
}

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

refresh_pulp_token
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
    curl -fsSL --retry 3 --retry-delay 5 "$PULP_CONTENT_URL/$BASE_PATH/dists/$TESTING_SUITE/main/binary-$ARCH/Packages" |
      awk -v sha="$SHA256" 'BEGIN { RS = ""; FS = "\n" } index($0, "SHA256: " sha) { for (i = 1; i <= NF; i++) if ($i ~ /^Filename: /) { sub(/^Filename: /, "", $i); print $i } }'
  )
  if [[ -z "$FILENAME" ]]; then
    echo "::error::Cannot locate the published file of $FILE_NAME (sha256 $SHA256) in $TESTING_SUITE"
    exit 1
  fi

  echo "[INFO] Downloading $PULP_CONTENT_URL/$BASE_PATH/$FILENAME"
  curl -fsSL --retry 3 --retry-delay 5 -o "$FILE" "$PULP_CONTENT_URL/$BASE_PATH/$FILENAME"

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
      -F "repository=$REPOSITORY_HREF" \
      -F "pulp_labels=$PULP_LABELS" \
      "$PULP_URL/api/v3/content/deb/packages/"
  )
  wait_task "$TASK_HREF"
done

if ((${#BATCH_PACKAGES[@]} > 0)); then
  # deduce the stable release-component href: the batch packages only carry
  # their testing association, the just-promoted legacy package carries the
  # stable one on top of it
  refresh_pulp_token
  FIRST_BATCH_HREF=$(echo "${BATCH_PACKAGES[0]}" | jq -r '.pulp_href')
  LEGACY_HREF=$(echo "${LEGACY_PACKAGES[0]}" | jq -r '.pulp_href')
  TESTING_RC=$(lookup_prcs "$FIRST_BATCH_HREF" | head -1)
  STABLE_RC=$(lookup_prcs "$LEGACY_HREF" | grep -Fxv "$TESTING_RC" | head -1)
  if [[ -z "$STABLE_RC" ]]; then
    echo "::error::Cannot deduce the $STABLE_SUITE/main release component from the legacy-promoted package"
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

  echo "[INFO] Adding ${#BATCH_PACKAGES[@]} package(s) and their suite associations to $REPOSITORY_NAME in a single task"
  refresh_pulp_token
  # body through a file: thousands of hrefs exceed the argv limit
  ADD_BODY_FILE=$(mktemp)
  jq -R . "$ADD_UNITS_FILE" | jq -cs '{add_content_units: [.[] | select(. != "")]}' > "$ADD_BODY_FILE"
  rm -f "$ADD_UNITS_FILE"
  MODIFY_TASK=$(
    curl -fsSL -H "Authorization: Github $PULP_TOKEN" \
      -X POST -H "Content-Type: application/json" \
      -d @"$ADD_BODY_FILE" \
      "$PULP_URL${REPOSITORY_HREF}modify/" | jq -r '.task'
  )
  wait_task "$MODIFY_TASK"
fi

# record the promoted packages (with their stable suite coordinates) so the
# verification step verifies exactly this set against the stable suite
while read -r PACKAGE; do
  manifest_add "$(echo "$PACKAGE" | jq -c \
    --arg repository "$REPOSITORY_NAME" --arg base_path "$BASE_PATH" \
    --arg suite "$STABLE_SUITE" \
    '{filename: (.relative_path | sub(".*/"; "")), name: .package, version, arch: .architecture, sha256, repository: $repository, base_path: $base_path, suite: $suite, relative_path}')"
done < <(echo "$PACKAGES" | jq -c '.[]')

echo "[INFO] Publishing repository $REPOSITORY_NAME"
create_publication deb "$REPOSITORY_NAME" --structured

echo "::notice::Packages are available with: deb $PULP_CONTENT_URL/$BASE_PATH/ $STABLE_SUITE main"

manifest_write "$MODULE_NAME" "${DISTRIB:-}" "deb" "$STABILITY" "promote" "$PULP_CONTENT_URL"
