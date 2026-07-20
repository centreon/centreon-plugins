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

declare -A ARCH_CONTENT
declare -A ARCH_RESULTS
TOTAL_PACKAGES_COUNT=0

for ARCH in noarch x86_64; do
  TESTING_REPOSITORY_NAME="$TESTING_REPOSITORY_PREFIX-$ARCH"

  if ! pulp rpm repository show --name "$TESTING_REPOSITORY_NAME" >/dev/null 2>&1; then
    echo "[INFO] Testing repository $TESTING_REPOSITORY_NAME does not exist"
    continue
  fi

  VERSION_HREF=$(pulp rpm repository show --name "$TESTING_REPOSITORY_NAME" | jq -r '.latest_version_href')

  # packages of the module are identified by the label set at delivery time;
  # keep both the href list (for the content modify call) and the package
  # identity (name/version/release/arch/filename) to feed the promotion manifest
  # paginate: the testing repository keeps every delivered version, so the
  # module listing can exceed a single page
  RESULTS_FILE=$(mktemp)
  url="$PULP_URL/api/v3/content/rpm/packages/?$(
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

  # only the LATEST build of each package is promoted: the version schemes
  # embed a monotonic date/timestamp so the plain string max is the newest
  RESULTS=$(jq -s '[.[] | {pulp_href, name, version, release, arch, location_href, sha256}]
    | group_by(.name, .arch) | map(max_by([.version, .release]))' "$RESULTS_FILE")
  rm -f "$RESULTS_FILE"
  CONTENT=$(echo "$RESULTS" | jq '[.[].pulp_href]')
  ARCH_PACKAGES_COUNT=$(echo "$CONTENT" | jq 'length')

  echo "[INFO] $ARCH_PACKAGES_COUNT $ARCH packages of module $MODULE_NAME found in $TESTING_REPOSITORY_NAME"
  ARCH_CONTENT[$ARCH]="$CONTENT"
  ARCH_RESULTS[$ARCH]="$RESULTS"
  TOTAL_PACKAGES_COUNT=$((TOTAL_PACKAGES_COUNT + ARCH_PACKAGES_COUNT))
done

if [[ "$TOTAL_PACKAGES_COUNT" -eq 0 ]]; then
  echo "::error::Nothing to promote, no package of module $MODULE_NAME found in $TESTING_REPOSITORY_PREFIX repositories"
  exit 1
fi

if [[ "$STABILITY" != "stable" ]]; then
  echo "[INFO] Dry run, $TOTAL_PACKAGES_COUNT packages would be promoted to $STABLE_REPOSITORY_PREFIX repositories"
  exit 0
fi

for ARCH in noarch x86_64; do
  CONTENT="${ARCH_CONTENT[$ARCH]:-[]}"
  ARCH_PACKAGES_COUNT=$(echo "$CONTENT" | jq 'length')

  if [[ "$ARCH_PACKAGES_COUNT" -eq 0 ]]; then
    echo "[INFO] No $ARCH package to promote"
    continue
  fi

  STABLE_REPOSITORY_NAME="$STABLE_REPOSITORY_PREFIX-$ARCH"
  STABLE_BASE_PATH="$STABLE_BASE_PATH_PREFIX/$ARCH"

  if ! pulp rpm repository show --name "$STABLE_REPOSITORY_NAME" >/dev/null 2>&1; then
    echo "::error::stable rpm repository $STABLE_REPOSITORY_NAME does not exist. Pulp repositories and distributions are provisioned centrally by delivery-tooling create-repos; run create-repos for this version before promoting."
    exit 1
  fi

  if ! pulp rpm distribution show --name "$STABLE_REPOSITORY_NAME" >/dev/null 2>&1; then
    echo "::error::stable rpm distribution $STABLE_REPOSITORY_NAME does not exist. Pulp distributions are provisioned centrally by delivery-tooling create-repos; run create-repos for this version before promoting. Refusing to create it here to avoid an unguarded distribution."
    exit 1
  fi

  STABLE_REPOSITORY_HREF=$(pulp rpm repository show --name "$STABLE_REPOSITORY_NAME" | jq -r '.pulp_href')

  echo "[INFO] Promoting $ARCH_PACKAGES_COUNT packages to $STABLE_REPOSITORY_NAME"
  # pulp-cli repository content modify does not resolve content by pulp_href, use the api directly
  TASK_HREF=$(
    curl -fsSL -H "Authorization: Github $PULP_TOKEN" \
      -X POST -H "Content-Type: application/json" \
      -d @<(echo "$CONTENT" | jq -c '{add_content_units: .}') \
      "$PULP_URL${STABLE_REPOSITORY_HREF}modify/" | jq -r '.task'
  )
  wait_task "$TASK_HREF"

  echo "[INFO] Publishing repository $STABLE_REPOSITORY_NAME"
  create_publication rpm "$STABLE_REPOSITORY_NAME"

  # record the promoted packages (with their stable target coordinates) so the
  # verification step verifies exactly this set against the stable repo
  while read -r PKG; do
    manifest_add "$(echo "$PKG" | jq -c \
      --arg repository "$STABLE_REPOSITORY_NAME" --arg base_path "$STABLE_BASE_PATH" \
      '{filename: (.location_href | sub(".*/"; "")), name, version, release, arch, sha256, repository: $repository, base_path: $base_path}')"
  done < <(echo "${ARCH_RESULTS[$ARCH]}" | jq -c '.[]')

  echo "::notice::Packages are available at $PULP_CONTENT_URL/$STABLE_BASE_PATH/"
done

manifest_write "$MODULE_NAME" "${DISTRIB:-}" "rpm" "$STABILITY" "promote" "$PULP_CONTENT_URL"
