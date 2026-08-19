#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

# shellcheck source=.github/scripts/pulp/manifest.sh
source "$(dirname "$0")/../../scripts/pulp/manifest.sh"
# shellcheck source=.github/scripts/pulp/api.sh
source "$(dirname "$0")/../../scripts/pulp/api.sh"

# an unset org variable is forwarded as an empty string, overriding the default
PULP_URL="${PULP_URL:-https://pulp-api.int.centreon.com}"
PULP_CONTENT_URL="${PULP_CONTENT_URL:-https://packages.int.centreon.com}"
PULP_DOMAIN="${PULP_DOMAIN:-default}"
# read-only grant into the stable domain, used by assert_not_in_stable below
PULP_STABLE_DOMAIN="${PULP_STABLE_DOMAIN:-default}"

# refuse delivering a package version already published in the stable repository
assert_not_in_stable() {
  local file=$1 arch=$2 base name version release stable_repository repository_version count
  base=$(basename "$file" .rpm)
  base=${base%.$arch}
  release=${base##*-}
  base=${base%-*}
  version=${base##*-}
  name=${base%-*}

  stable_repository="$STABLE_REPOSITORY_PREFIX-$arch"
  # fail closed on an unreachable api, fail open only if the repo doesn't exist yet
  local repo_page
  repo_page=$(
    curl -fsSL --retry 3 --retry-delay 5 -H "Authorization: Bearer $PULP_TOKEN" -G \
      --data-urlencode "name=$stable_repository" \
      --data-urlencode "limit=1" \
      "$PULP_URL/$PULP_STABLE_DOMAIN/api/v3/repositories/rpm/rpm/"
  ) || {
    echo "::error::Cannot check the stable repository $stable_repository to guard $name $version-$release ($arch); refusing to deliver. Retry once the api is reachable."
    return 1
  }
  repository_version=$(echo "$repo_page" | jq -r '.results[0].latest_version_href // empty')
  # no stable repository yet => nothing can be in stable
  [[ -z "$repository_version" ]] && return 0

  count=$(
    curl -fsSL --retry 3 --retry-delay 5 -H "Authorization: Bearer $PULP_TOKEN" -G \
      --data-urlencode "repository_version=$repository_version" \
      --data-urlencode "name=$name" \
      --data-urlencode "version=$version" \
      --data-urlencode "release=$release" \
      --data-urlencode "arch=$arch" \
      --data-urlencode "limit=1" \
      "$PULP_URL/$PULP_STABLE_DOMAIN/api/v3/content/rpm/packages/" | jq -r '.count'
  ) || {
    echo "::error::Cannot check the stable repository $stable_repository content to guard $name $version-$release ($arch); refusing to deliver. Retry once the api is reachable."
    return 1
  }
  if [[ "$count" -gt 0 ]]; then
    echo "::error::$name $version-$release ($arch) is already published in the stable repository $stable_repository; refusing to deliver it to $REPOSITORY_NAME. Bump the package version for a new build."
    return 1
  fi
}

# wait for the upload task and emit its content href; fall back to a sha256
# lookup if the task produced none (content already existing on a job re-run)
resolve_uploaded_content() {
  local task_href=$1 sha256=$2
  local body state content attempt
  for ((attempt = 0; attempt < 200; attempt++)); do
    refresh_pulp_token
    body=$(curl -fsSL -H "Authorization: Bearer $PULP_TOKEN" "$PULP_URL$task_href" 2>/dev/null) || body=""
    state=$(echo "$body" | jq -r '.state' 2>/dev/null) || state=""
    case "$state" in
      completed)
        content=$(echo "$body" | jq -r '.created_resources[0] // empty')
        if [[ -n "$content" ]]; then
          echo "$content"
          return 0
        fi
        break
        ;;
      failed | canceled)
        break
        ;;
      *)
        sleep 3
        ;;
    esac
  done
  content=$(
    curl -fsSL -H "Authorization: Bearer $PULP_TOKEN" -G \
      --data-urlencode "sha256=$sha256" \
      --data-urlencode "limit=1" \
      "$PULP_URL/$PULP_DOMAIN/api/v3/content/rpm/packages/" | jq -r '.results[0].pulp_href // empty'
  )
  if [[ -z "$content" ]]; then
    echo "::error::Cannot resolve the uploaded content for task $task_href (sha256 $sha256)" >&2
    return 1
  fi
  echo "$content"
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

  if ! pulp_resource_exists "repositories/rpm/rpm" "$REPOSITORY_NAME"; then
    echo "::error::rpm repository $REPOSITORY_NAME does not exist. Pulp repositories and distributions are provisioned centrally by delivery-tooling create-repos; run create-repos for this version before delivering."
    exit 1
  fi

  if ! pulp_resource_exists "distributions/rpm/rpm" "$REPOSITORY_NAME"; then
    echo "::error::rpm distribution $REPOSITORY_NAME does not exist. Pulp distributions are provisioned centrally by delivery-tooling create-repos; run create-repos for this version before delivering. Refusing to create it here to avoid an unguarded distribution."
    exit 1
  fi

  REPOSITORY_HREF=$(pulp rpm repository show --name "$REPOSITORY_NAME" | jq -r '.pulp_href')

  # upload as unassociated (repository-less) content so creates parallelize
  # across pulp workers, then add the whole batch in one modify task
  TASK_HREFS=()
  SHA256S=()
  # bounded pool of background subshells upload in parallel, each writing its
  # task href to a marker file; a missing/empty marker means that worker failed
  UPLOAD_DIR=$(mktemp -d)
  MAX_PARALLEL_UPLOADS=8
  for i in "${!ARCH_FILES[@]}"; do
    FILE=${ARCH_FILES[$i]}
    if ((i % 40 == 0)); then
      refresh_pulp_token
    fi
    (
      # subshell-local: the inherited token can go stale between parent refreshes
      refresh_pulp_token
      assert_not_in_stable "$FILE" "$ARCH"
      echo "[INFO] Uploading $(basename "$FILE") (module $MODULE_NAME)"
      pulp_upload \
        -F "file=@\"$FILE\"" \
        -F "pulp_labels=$PULP_LABELS" \
        "$PULP_URL/$PULP_DOMAIN/api/v3/content/rpm/packages/" > "$UPLOAD_DIR/$i.task"
    ) &
    while (($(jobs -rp | wc -l) >= MAX_PARALLEL_UPLOADS)); do
      wait -n || true
    done
  done
  wait || true

  for i in "${!ARCH_FILES[@]}"; do
    FILE=${ARCH_FILES[$i]}
    if [[ ! -s "$UPLOAD_DIR/$i.task" ]]; then
      echo "::error::Upload failed for $(basename "$FILE") (no task href, see the worker error above)"
      exit 1
    fi
    TASK_HREFS+=("$(cat "$UPLOAD_DIR/$i.task")")
    sha256=$(sha256sum "$FILE" | cut -d' ' -f1)
    SHA256S+=("$sha256")

    # name/version/release parsed the same way as assert_not_in_stable
    FILENAME=$(basename "$FILE")
    base=${FILENAME%.rpm}
    base=${base%."$ARCH"}
    release=${base##*-}
    base=${base%-*}
    version=${base##*-}
    name=${base%-*}
    manifest_add "$(jq -cn \
      --arg filename "$FILENAME" --arg name "$name" --arg version "$version" \
      --arg release "$release" --arg arch "$ARCH" --arg sha256 "$sha256" \
      --arg repository "$REPOSITORY_NAME" --arg base_path "$BASE_PATH" \
      '{filename:$filename,name:$name,version:$version,release:$release,arch:$arch,sha256:$sha256,repository:$repository,base_path:$base_path}')"
  done
  rm -rf "$UPLOAD_DIR"

  echo "[INFO] Waiting for ${#TASK_HREFS[@]} upload task(s) and resolving the content"
  # parallelized like the uploads: sequential took one task GET per package (~6 min at 675)
  RESOLVE_DIR=$(mktemp -d)
  for i in "${!TASK_HREFS[@]}"; do
    if ((i % 40 == 0)); then
      refresh_pulp_token
    fi
    (
      resolve_uploaded_content "${TASK_HREFS[$i]}" "${SHA256S[$i]}" > "$RESOLVE_DIR/$i.content"
    ) &
    while (($(jobs -rp | wc -l) >= MAX_PARALLEL_UPLOADS)); do
      wait -n || true
    done
  done
  wait || true

  CONTENT_HREFS=()
  for i in "${!TASK_HREFS[@]}"; do
    if [[ ! -s "$RESOLVE_DIR/$i.content" ]]; then
      echo "::error::Cannot resolve the uploaded content of task ${TASK_HREFS[$i]} (see the worker error above)"
      exit 1
    fi
    CONTENT_HREFS+=("$(cat "$RESOLVE_DIR/$i.content")")
  done
  rm -rf "$RESOLVE_DIR"

  echo "[INFO] Adding ${#CONTENT_HREFS[@]} package(s) to $REPOSITORY_NAME in a single task"
  # the subshell refreshes above never updated this shell's token
  refresh_pulp_token
  # body through a file: thousands of hrefs exceed the argv limit
  ADD_BODY_FILE=$(mktemp)
  printf '%s\n' "${CONTENT_HREFS[@]}" | jq -R . | jq -cs '{add_content_units: .}' > "$ADD_BODY_FILE"
  # several modules deliver into the same repository (version race)
  for modify_attempt in 1 2 3; do
    MODIFY_TASK=$(start_modify_task "$PULP_URL${REPOSITORY_HREF}modify/" "$ADD_BODY_FILE")
    wait_task_race "$MODIFY_TASK" && rc=0 || rc=$?
    if [[ $rc -eq 0 ]]; then
      break
    elif [[ $rc -eq 2 && $modify_attempt -lt 3 ]]; then
      echo "[WARN] Repository modify was interrupted server-side, retrying"
      sleep $((modify_attempt * 15))
    else
      echo "::error::Repository modify failed"
      exit 1
    fi
  done

  echo "[INFO] Publishing repository $REPOSITORY_NAME"
  create_publication rpm "$REPOSITORY_NAME"

  echo "::notice::Packages are available at $PULP_CONTENT_URL/$PULP_DOMAIN/$BASE_PATH/"
done

manifest_write "$MODULE_NAME" "${DISTRIB:-}" "rpm" "${STABILITY:-}" "delivery" "$PULP_CONTENT_URL"
