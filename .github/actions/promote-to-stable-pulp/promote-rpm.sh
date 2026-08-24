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
declare -A ARCH_CONTENT
declare -A ARCH_RESULTS
TOTAL_PACKAGES_COUNT=0

for ARCH in noarch x86_64; do
  TESTING_REPOSITORY_NAME="$TESTING_REPOSITORY_PREFIX-$ARCH"

  if ! pulp_resource_exists "repositories/rpm/rpm" "$TESTING_REPOSITORY_NAME"; then
    echo "[INFO] Testing repository $TESTING_REPOSITORY_NAME does not exist"
    continue
  fi

  VERSION_HREF=$(pulp rpm repository show --name "$TESTING_REPOSITORY_NAME" | jq -r '.latest_version_href')

  # paginate: the testing repository keeps every delivered version, so the
  # module listing can exceed a single page
  RESULTS_FILE=$(mktemp)
  url="$PULP_URL/$PULP_DOMAIN/api/v3/content/rpm/packages/?$(
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

  # only the LATEST build of each package is promoted; compare version/release
  # segment by segment (numeric as numbers) since a plain string max ranks "0.9" above "0.10"
  RESULTS=$(jq -s 'def vkey: [scan("[0-9]+|[^0-9]+") | (tonumber? // .)];
    [.[] | {pulp_href, name, version, release, arch, location_href, sha256}]
    | group_by(.name, .arch) | map(max_by([(.version | vkey), (.release | vkey)]))' "$RESULTS_FILE")
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

# everything from here on targets the stable-tier domain
refresh_pulp_token
switch_pulp_domain "$PULP_STABLE_DOMAIN"

for ARCH in noarch x86_64; do
  CONTENT="${ARCH_CONTENT[$ARCH]:-[]}"
  RESULTS="${ARCH_RESULTS[$ARCH]:-[]}"
  ARCH_PACKAGES_COUNT=$(echo "$CONTENT" | jq 'length')

  if [[ "$ARCH_PACKAGES_COUNT" -eq 0 ]]; then
    echo "[INFO] No $ARCH package to promote"
    continue
  fi

  STABLE_REPOSITORY_NAME="$STABLE_REPOSITORY_PREFIX-$ARCH"
  STABLE_BASE_PATH="$STABLE_BASE_PATH_PREFIX/$ARCH"

  if ! pulp_resource_exists "repositories/rpm/rpm" "$STABLE_REPOSITORY_NAME"; then
    echo "::error::stable rpm repository $STABLE_REPOSITORY_NAME does not exist. Pulp repositories and distributions are provisioned centrally by delivery-tooling create-repos; run create-repos for this version before promoting."
    exit 1
  fi

  if ! pulp_resource_exists "distributions/rpm/rpm" "$STABLE_REPOSITORY_NAME"; then
    echo "::error::stable rpm distribution $STABLE_REPOSITORY_NAME does not exist. Pulp distributions are provisioned centrally by delivery-tooling create-repos; run create-repos for this version before promoting. Refusing to create it here to avoid an unguarded distribution."
    exit 1
  fi

  STABLE_REPOSITORY_HREF=$(pulp rpm repository show --name "$STABLE_REPOSITORY_NAME" | jq -r '.pulp_href')

  # Same-domain promotion: testing and stable share their domain, so the
  # testing content hrefs (already collected above) are associated with the
  # stable repository directly — no re-download/re-upload, the packages keep
  # their delivery-time labels (check-rpm.sh only needs "module").
  echo "[INFO] Promoting $ARCH_PACKAGES_COUNT packages to $STABLE_REPOSITORY_NAME"
  # pulp-cli repository content modify does not resolve content by pulp_href, use the api directly
  ADD_BODY_FILE=$(mktemp)
  echo "$CONTENT" | jq -c '{add_content_units: .}' > "$ADD_BODY_FILE"
  # retried like the deb path: concurrent promotions can race on the repository version
  for modify_attempt in 1 2 3; do
    TASK_HREF=$(start_modify_task "$PULP_URL${STABLE_REPOSITORY_HREF}modify/" "$ADD_BODY_FILE")
    wait_task_race "$TASK_HREF" && rc=0 || rc=$?
    if [[ $rc -eq 0 ]]; then
      break
    elif [[ $rc -eq 2 && $modify_attempt -lt 3 ]]; then
      echo "[WARN] Stable repository modify was interrupted server-side, retrying"
      sleep $((modify_attempt * 15))
    else
      echo "::error::Stable repository modify failed"
      exit 1
    fi
  done

  echo "[INFO] Publishing repository $STABLE_REPOSITORY_NAME"
  create_publication rpm "$STABLE_REPOSITORY_NAME"

  # record the promoted packages (with their stable target coordinates) so the
  # verification step verifies exactly this set against the stable repo
  while read -r PKG; do
    manifest_add "$(echo "$PKG" | jq -c \
      --arg repository "$STABLE_REPOSITORY_NAME" --arg base_path "$STABLE_BASE_PATH" \
      '{filename: (.location_href | sub(".*/"; "")), name, version, release, arch, sha256, repository: $repository, base_path: $base_path}')"
  done < <(echo "${ARCH_RESULTS[$ARCH]}" | jq -c '.[]')

  echo "::notice::Packages are available at $PULP_CONTENT_URL/$PULP_STABLE_DOMAIN/$STABLE_BASE_PATH/"
done

manifest_write "$MODULE_NAME" "${DISTRIB:-}" "rpm" "$STABILITY" "promote" "$PULP_CONTENT_URL"
