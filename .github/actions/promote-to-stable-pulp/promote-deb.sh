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
# scopes the distribution as the apt repository holds all the suites
RESPONSE=$(
  curl -fsSL -H "Authorization: Github $PULP_TOKEN" -G \
    --data-urlencode "repository_version=$VERSION_HREF" \
    --data-urlencode "pulp_label_select=module=$MODULE_NAME" \
    --data-urlencode "limit=1000" \
    "$PULP_URL/api/v3/content/deb/packages/"
)

# fail on a truncated page (checked before the pool-path filtering): silently
# promoting a subset of the module's packages would publish an incomplete
# stable suite
if [[ $(echo "$RESPONSE" | jq '.count > (.results | length)') == "true" ]]; then
  echo "::error::Package query on $REPOSITORY_NAME is truncated ($(echo "$RESPONSE" | jq -r '.results | length')/$(echo "$RESPONSE" | jq -r '.count') results); pagination is required"
  exit 1
fi

PACKAGES=$(
  echo "$RESPONSE" | \
    jq --arg testing_path "$TESTING_POOL_PATH/" --arg distrib_name "$PACKAGE_DISTRIB_NAME" \
      '[.results[] | select((.relative_path | startswith($testing_path)) and (.relative_path | contains($distrib_name)))]'
)
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

while read -r PACKAGE; do
  RELATIVE_PATH=$(echo "$PACKAGE" | jq -r '.relative_path')
  SHA256=$(echo "$PACKAGE" | jq -r '.sha256')
  ARCH=$(echo "$PACKAGE" | jq -r '.architecture')
  FILE_NAME=$(basename "$RELATIVE_PATH")
  FILE="promoted-packages/$FILE_NAME"

  # the structured publication serves packages under the canonical debian pool
  # layout, not their upload relative_path, so resolve the published location
  # from the testing suite Packages indexed by checksum to download the file
  FILENAME=$(
    curl -fsSL "$PULP_CONTENT_URL/$BASE_PATH/dists/$TESTING_SUITE/main/binary-$ARCH/Packages" |
      awk -v sha="$SHA256" 'BEGIN { RS = ""; FS = "\n" } index($0, "SHA256: " sha) { for (i = 1; i <= NF; i++) if ($i ~ /^Filename: /) { sub(/^Filename: /, "", $i); print $i } }'
  )
  if [[ -z "$FILENAME" ]]; then
    echo "::error::Cannot locate the published file of $FILE_NAME (sha256 $SHA256) in $TESTING_SUITE"
    exit 1
  fi

  echo "[INFO] Downloading $PULP_CONTENT_URL/$BASE_PATH/$FILENAME"
  curl -fsSL -o "$FILE" "$PULP_CONTENT_URL/$BASE_PATH/$FILENAME"

  # re-upload the same bytes with the SAME relative_path: pulp reuses the
  # existing content unit (a different relative_path would create a second unit
  # that evicts the first, as pulp deduplicates by name+version+architecture
  # repository wide) and only adds the stable suite association. an upload is
  # required because pulp_deb rejects direct PackageReleaseComponent creation.
  echo "[INFO] Promoting $FILE_NAME to $STABLE_SUITE/main"
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

  # record the promoted package (with its stable suite coordinates) so the
  # verification step verifies exactly this set against the stable suite
  NAME=$(echo "$PACKAGE" | jq -r '.package')
  VERSION=$(echo "$PACKAGE" | jq -r '.version')
  manifest_add "$(jq -cn \
    --arg filename "$FILE_NAME" --arg name "$NAME" --arg version "$VERSION" \
    --arg arch "$ARCH" --arg sha256 "$SHA256" --arg repository "$REPOSITORY_NAME" \
    --arg base_path "$BASE_PATH" --arg suite "$STABLE_SUITE" --arg relative_path "$RELATIVE_PATH" \
    '{filename:$filename,name:$name,version:$version,arch:$arch,sha256:$sha256,repository:$repository,base_path:$base_path,suite:$suite,relative_path:$relative_path}')"
done < <(echo "$PACKAGES" | jq -c '.[]')

echo "[INFO] Publishing repository $REPOSITORY_NAME"
pulp deb publication create --repository "$REPOSITORY_NAME" --structured >/dev/null

echo "::notice::Packages are available with: deb $PULP_CONTENT_URL/$BASE_PATH/ $STABLE_SUITE main"

manifest_write "$MODULE_NAME" "${DISTRIB:-}" "deb" "$STABILITY" "promote" "$PULP_CONTENT_URL"
