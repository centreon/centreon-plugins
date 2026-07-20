#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

# shellcheck source=.github/scripts/pulp/manifest.sh
source "$(dirname "$0")/../../scripts/pulp/manifest.sh"
# shellcheck source=.github/scripts/pulp/api.sh
source "$(dirname "$0")/../../scripts/pulp/api.sh"

# use the org-variable values, falling back to the defaults when passed empty
# (an unset org variable is forwarded as an empty string, overriding the default)
PULP_URL="${PULP_URL:-https://pulp-api.apps.centreon.com}"
PULP_CONTENT_URL="${PULP_CONTENT_URL:-https://packages.apps.centreon.com}"

# refuse delivering a package that is already published in the stable repository.
# rebuilding a testing/unstable version with a different content is fine, but a
# version that already reached stable must never be re-delivered. rpm uses a
# dedicated repository per stability, so this is a policy check (deliveries to
# testing/unstable cannot evict stable, unlike a shared repository).
assert_not_in_stable() {
  local file=$1 arch=$2 base name version release stable_repository repository_version count
  base=$(basename "$file" .rpm)
  base=${base%.$arch}
  release=${base##*-}
  base=${base%-*}
  version=${base##*-}
  name=${base%-*}

  stable_repository="$STABLE_REPOSITORY_PREFIX-$arch"
  # no stable repository yet => nothing can be in stable
  if ! pulp rpm repository show --name "$stable_repository" >/dev/null 2>&1; then
    return 0
  fi
  repository_version=$(pulp rpm repository show --name "$stable_repository" | jq -r '.latest_version_href')

  count=$(
    curl -fsSL -H "Authorization: Github $PULP_TOKEN" -G \
      --data-urlencode "repository_version=$repository_version" \
      --data-urlencode "name=$name" \
      --data-urlencode "version=$version" \
      --data-urlencode "release=$release" \
      --data-urlencode "arch=$arch" \
      --data-urlencode "limit=1" \
      "$PULP_URL/api/v3/content/rpm/packages/" | jq -r '.count'
  )
  if [[ "$count" -gt 0 ]]; then
    echo "::error::$name $version-$release ($arch) is already published in the stable repository $stable_repository; refusing to deliver it to $REPOSITORY_NAME. Bump the package version for a new build."
    return 1
  fi
}

FILES=(*.rpm)
if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "::error::No rpm package found to deliver"
  exit 1
fi

mkdir -p noarch x86_64
for FILE in "${FILES[@]}"; do
  ARCH=$(echo "$FILE" | grep -oP '(x86_64|noarch)' | head -1 || true)
  if [[ -z "$ARCH" ]]; then
    echo "::error::Cannot find the architecture of package $FILE"
    exit 1
  fi
  mv "$FILE" "$ARCH"
done

PULP_LABELS=$(jq -cn \
  --arg mod        "$MODULE_NAME" \
  --arg git_commit "${GITHUB_SHA:-}" \
  --arg git_ref    "${GITHUB_REF:-}" \
  --arg run_id     "${GITHUB_RUN_ID:-}" \
  --arg actor      "${GITHUB_ACTOR:-}" \
  --arg workflow   "${GITHUB_WORKFLOW:-}" \
  '{"module": $mod, "git_commit": $git_commit, "git_ref": $git_ref, "github_run_id": $run_id, "github_actor": $actor, "github_workflow": $workflow}')

for ARCH in noarch x86_64; do
  ARCH_FILES=("$ARCH"/*.rpm)
  if [[ ${#ARCH_FILES[@]} -eq 0 ]]; then
    continue
  fi

  REPOSITORY_NAME="$REPOSITORY_PREFIX-$ARCH"
  BASE_PATH="$BASE_PATH_PREFIX/$ARCH"

  if ! pulp rpm repository show --name "$REPOSITORY_NAME" >/dev/null 2>&1; then
    echo "::error::rpm repository $REPOSITORY_NAME does not exist. Pulp repositories and distributions are provisioned centrally by delivery-tooling create-repos; run create-repos for this version before delivering."
    exit 1
  fi

  if ! pulp rpm distribution show --name "$REPOSITORY_NAME" >/dev/null 2>&1; then
    echo "::error::rpm distribution $REPOSITORY_NAME does not exist. Pulp distributions are provisioned centrally by delivery-tooling create-repos; run create-repos for this version before delivering. Refusing to create it here to avoid an unguarded distribution."
    exit 1
  fi

  REPOSITORY_HREF=$(pulp rpm repository show --name "$REPOSITORY_NAME" | jq -r '.pulp_href')

  # Packages are uploaded straight into the repository: pulpcore requires
  # non-admin accounts to provide the destination repository on content upload,
  # so the upload cannot be decoupled from the repository association. Packages
  # are labeled with their module so that promote-to-stable can identify them;
  # pulp-cli does not allow to set labels on upload so the api is used directly.
  for FILE in "${ARCH_FILES[@]}"; do
    assert_not_in_stable "$FILE" "$ARCH"
    echo "[INFO] Uploading $(basename "$FILE") to $REPOSITORY_NAME (module $MODULE_NAME)"
    TASK_HREF=$(
      pulp_upload \
        -F "file=@\"$FILE\"" \
        -F "repository=$REPOSITORY_HREF" \
        -F "pulp_labels=$PULP_LABELS" \
        "$PULP_URL/api/v3/content/rpm/packages/"
    )
    wait_task "$TASK_HREF"

    # record the uploaded package in the manifest (name-version-release parsed
    # the same way as assert_not_in_stable) for the verification step
    FILENAME=$(basename "$FILE")
    base=${FILENAME%.rpm}
    base=${base%."$ARCH"}
    release=${base##*-}
    base=${base%-*}
    version=${base##*-}
    name=${base%-*}
    sha256=$(sha256sum "$FILE" | cut -d' ' -f1)
    manifest_add "$(jq -cn \
      --arg filename "$FILENAME" --arg name "$name" --arg version "$version" \
      --arg release "$release" --arg arch "$ARCH" --arg sha256 "$sha256" \
      --arg repository "$REPOSITORY_NAME" --arg base_path "$BASE_PATH" \
      '{filename:$filename,name:$name,version:$version,release:$release,arch:$arch,sha256:$sha256,repository:$repository,base_path:$base_path}')"
  done

  echo "[INFO] Publishing repository $REPOSITORY_NAME"
  pulp rpm publication create --repository "$REPOSITORY_NAME" >/dev/null

  echo "::notice::Packages are available at $PULP_CONTENT_URL/$BASE_PATH/"
done

manifest_write "$MODULE_NAME" "${DISTRIB:-}" "rpm" "${STABILITY:-}" "delivery" "$PULP_CONTENT_URL"
