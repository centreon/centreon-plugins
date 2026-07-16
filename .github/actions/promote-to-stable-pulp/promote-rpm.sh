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
  RESPONSE=$(
    curl -fsSL -H "Authorization: Github $PULP_TOKEN" -G \
      --data-urlencode "repository_version=$VERSION_HREF" \
      --data-urlencode "pulp_label_select=module=$MODULE_NAME" \
      --data-urlencode "limit=1000" \
      "$PULP_URL/api/v3/content/rpm/packages/"
  )

  # fail on a truncated page: silently promoting a subset of the module's
  # packages would publish an incomplete stable repository
  if [[ $(echo "$RESPONSE" | jq '.count > (.results | length)') == "true" ]]; then
    echo "::error::Package query on $TESTING_REPOSITORY_NAME is truncated ($(echo "$RESPONSE" | jq -r '.results | length')/$(echo "$RESPONSE" | jq -r '.count') results); pagination is required"
    exit 1
  fi

  RESULTS=$(echo "$RESPONSE" | jq '[.results[] | {pulp_href, name, version, release, arch, location_href, sha256}]')
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
      -d "{\"add_content_units\": $CONTENT}" \
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
