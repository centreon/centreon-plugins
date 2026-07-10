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

# refuse delivering a package that is already published in the stable suite.
# rebuilding a testing/unstable version with a different content is fine, but a
# version that already reached stable must never be re-delivered: pulp
# deduplicates packages by (package, version, architecture) repository wide, so
# the new content would silently evict the stable one. bump the version instead.
assert_not_in_stable() {
  local file=$1 name version arch packages http_code pkg_file
  name=$(dpkg-deb -f "$file" Package)
  version=$(dpkg-deb -f "$file" Version)
  arch=$(dpkg-deb -f "$file" Architecture)

  # the published stable suite is the source of truth for what reached stable.
  # the release_components api is not listable by the OIDC ci-user (403, and no
  # grantable permission exists for it), so check the served Packages index
  # instead: no api access needed and it reflects exactly what stable publishes.
  # distinguish "not published yet" (404 -> not in stable) from a fetch failure
  # (network / 5xx -> unknown): fail closed on the latter, so a transient content
  # endpoint error cannot let an already-stable version slip through and evict it
  # (the rpm guardrail is likewise fail-closed).
  pkg_file=$(mktemp)
  http_code=$(curl -sSL -o "$pkg_file" -w '%{http_code}' \
    "$PULP_CONTENT_URL/$BASE_PATH/dists/$STABLE_SUITE/main/binary-$arch/Packages" 2>/dev/null || echo 000)
  case "$http_code" in
    404) rm -f "$pkg_file"; return 0 ;;
    200) packages=$(cat "$pkg_file"); rm -f "$pkg_file" ;;
    *)
      rm -f "$pkg_file"
      echo "::error::Cannot verify the stable suite $STABLE_SUITE (HTTP $http_code) to guard $name $version ($arch); refusing to deliver. Retry once the content endpoint is reachable."
      return 1
      ;;
  esac
  # empty index -> nothing in stable
  [[ -z "$packages" ]] && return 0

  # a package is in stable if a Packages stanza matches both name and version
  if printf '%s\n' "$packages" | awk -v n="$name" -v v="$version" '
       BEGIN { RS = ""; FS = "\n" }
       {
         has_name = 0; has_version = 0
         for (i = 1; i <= NF; i++) {
           if ($i == "Package: " n) has_name = 1
           if ($i == "Version: " v) has_version = 1
         }
         if (has_name && has_version) found = 1
       }
       END { exit found ? 0 : 1 }
     '; then
    echo "::error::$name $version ($arch) is already published in the stable suite $STABLE_SUITE; refusing to deliver it to $SUITE. Bump the package version for a new build."
    return 1
  fi
}

FILES=(*.deb)
if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "::error::No deb package found to deliver"
  exit 1
fi

if ! pulp deb repository show --name "$REPOSITORY_NAME" >/dev/null 2>&1; then
  echo "::error::deb repository $REPOSITORY_NAME does not exist. Pulp repositories and distributions are provisioned centrally by delivery-tooling create-repos; run create-repos for this version before delivering."
  exit 1
fi

if ! pulp deb distribution show --name "$REPOSITORY_NAME" >/dev/null 2>&1; then
  echo "::error::deb distribution $REPOSITORY_NAME does not exist. Pulp distributions are provisioned centrally by delivery-tooling create-repos; run create-repos for this version before delivering. Refusing to create it here to avoid an unguarded distribution."
  exit 1
fi

REPOSITORY_HREF=$(pulp deb repository show --name "$REPOSITORY_NAME" | jq -r '.pulp_href')

PULP_LABELS=$(jq -cn \
  --arg mod        "$MODULE_NAME" \
  --arg git_commit "${GITHUB_SHA:-}" \
  --arg git_ref    "${GITHUB_REF:-}" \
  --arg run_id     "${GITHUB_RUN_ID:-}" \
  --arg actor      "${GITHUB_ACTOR:-}" \
  --arg workflow   "${GITHUB_WORKFLOW:-}" \
  '{"module": $mod, "git_commit": $git_commit, "git_ref": $git_ref, "github_run_id": $run_id, "github_actor": $actor, "github_workflow": $workflow}')

for FILE in "${FILES[@]}"; do
  assert_not_in_stable "$FILE"
  echo "[INFO] Uploading $FILE to $POOL_PATH/ ($SUITE/main, module $MODULE_NAME)"
  # packages are labeled with their module so that promote-to-stable can identify
  # which packages belong to this module, pulp-cli does not allow to set labels nor
  # the relative path of deb packages so the api is used directly
  TASK_HREF=$(
    pulp_upload \
      -F "file=@\"$FILE\"" \
      -F "relative_path=$POOL_PATH/$FILE" \
      -F "distribution=$SUITE" \
      -F "component=main" \
      -F "repository=$REPOSITORY_HREF" \
      -F "pulp_labels=$PULP_LABELS" \
      "$PULP_URL/api/v3/content/deb/packages/"
  )
  wait_task "$TASK_HREF"

  # record the uploaded package in the manifest for the verification step
  name=$(dpkg-deb -f "$FILE" Package)
  version=$(dpkg-deb -f "$FILE" Version)
  arch=$(dpkg-deb -f "$FILE" Architecture)
  sha256=$(sha256sum "$FILE" | cut -d' ' -f1)
  manifest_add "$(jq -cn \
    --arg filename "$FILE" --arg name "$name" --arg version "$version" \
    --arg arch "$arch" --arg sha256 "$sha256" --arg repository "$REPOSITORY_NAME" \
    --arg base_path "$BASE_PATH" --arg suite "$SUITE" --arg relative_path "$POOL_PATH/$FILE" \
    '{filename:$filename,name:$name,version:$version,arch:$arch,sha256:$sha256,repository:$repository,base_path:$base_path,suite:$suite,relative_path:$relative_path}')"
done

echo "[INFO] Publishing repository $REPOSITORY_NAME"
pulp deb publication create --repository "$REPOSITORY_NAME" --structured >/dev/null

echo "::notice::Packages are available with: deb $PULP_CONTENT_URL/$BASE_PATH/ $SUITE main"

manifest_write "$MODULE_NAME" "${DISTRIB:-}" "deb" "${STABILITY:-}" "delivery" "$PULP_CONTENT_URL"
