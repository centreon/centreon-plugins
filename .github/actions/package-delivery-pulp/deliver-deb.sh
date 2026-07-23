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
  http_code=$(content_curl -sSL --retry 3 --retry-delay 5 -o "$pkg_file" -w '%{http_code}' \
    "$PULP_CONTENT_URL/${STABLE_BASE_PATH:-$BASE_PATH}/dists/$STABLE_SUITE/main/binary-$arch/Packages" 2>/dev/null || echo 000)
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

# Batched delivery, deb flavor. Unlike
# rpm, a repository-less deb upload ignores the distribution/component
# parameters (pulp_deb only creates the suite association inside the
# repository code path), so the suite association is created explicitly as
# PackageReleaseComponent content units. The release_components api is not
# listable by the OIDC ci-user, so the FIRST package of each architecture is
# delivered through the legacy repository code path - that also
# get_or_creates the ReleaseComponent and the ReleaseArchitecture of the
# suite - and its PackageReleaseComponent (listable) yields the release
# component href for the whole batch. Everything else is uploaded as
# unassociated content in a client-side pool, associated in parallel tasks
# (no repository lock), then added to the repository with a single modify.
lookup_deb_content() {
  # emit the href of a deb content unit matching the query, empty if absent.
  # Every caller sits on a fallback path where the content is expected to
  # exist, so an empty result is retried too: the api has been observed
  # answering an empty page for content committed seconds earlier (stale
  # read), and a transient error must not read as "content absent" either.
  local endpoint=$1 query=$2 out attempt
  for attempt in 1 2 3 4 5; do
    out=$(curl -fsSL --retry 3 --retry-delay 5 -H "Authorization: Github $PULP_TOKEN" -G \
      --data-urlencode "limit=1" \
      $query \
      "$PULP_URL/api/v3/content/deb/$endpoint/" | jq -r '.results[0].pulp_href // empty') || out=""
    if [[ -n "$out" ]]; then
      echo "$out"
      return 0
    fi
    sleep $((attempt * 3))
    refresh_pulp_token
  done
}

resolve_task_content() {
  # wait for a content-create task and emit its created content href; fall
  # back to a lookup (content already existing on a job re-run)
  local task_href=$1 endpoint=$2 fallback_query=$3
  local body state content attempt
  for ((attempt = 0; attempt < 200; attempt++)); do
    refresh_pulp_token
    body=$(curl -fsSL -H "Authorization: Github $PULP_TOKEN" "$PULP_URL$task_href" 2>/dev/null) || body=""
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
  content=$(lookup_deb_content "$endpoint" "$fallback_query")
  if [[ -z "$content" ]]; then
    echo "::error::Cannot resolve the created deb content for task $task_href" >&2
    return 1
  fi
  echo "$content"
}

# emit the release-component hrefs a package is associated with
lookup_prcs() {
  local package_href=$1
  curl -fsSL --retry 3 --retry-delay 5 -H "Authorization: Github $PULP_TOKEN" -G \
    --data-urlencode "package=$package_href" \
    --data-urlencode "limit=100" \
    "$PULP_URL/api/v3/content/deb/package_release_components/" \
    | jq -r '.results[].release_component'
}

# group the files by architecture: one file per arch goes through the legacy
# path so the suite association targets of that arch exist. Prefer a file
# whose content does NOT exist in pulp yet: a fresh upload carries exactly
# one suite association afterwards, which identifies the release component
# unambiguously. Content reused across suites (identical bytes delivered to
# another suite before) keeps its prior associations, so for a reused
# representative the pre-upload association set is captured to diff later.
declare -A LEGACY_FOR_ARCH=()
declare -A LEGACY_FRESH=()
declare -A LEGACY_BEFORE=()
refresh_pulp_token
for i in "${!FILES[@]}"; do
  FILE=${FILES[$i]}
  arch=$(dpkg-deb -f "$FILE" Architecture)
  if [[ -n "${LEGACY_FRESH[$arch]+set}" ]]; then
    continue
  fi
  if ((i % 40 == 0)); then
    refresh_pulp_token
  fi
  sha=$(sha256sum "$FILE" | cut -d' ' -f1)
  existing=$(lookup_deb_content "packages" "--data-urlencode sha256=$sha")
  if [[ -z "$existing" ]]; then
    LEGACY_FOR_ARCH[$arch]="$FILE"
    LEGACY_FRESH[$arch]=1
  elif [[ -z "${LEGACY_FOR_ARCH[$arch]+set}" ]]; then
    LEGACY_FOR_ARCH[$arch]="$FILE"
    LEGACY_BEFORE[$arch]=$(lookup_prcs "$existing" | sort)
  fi
done

declare -A IS_LEGACY=()
LEGACY_FILES=()
LEGACY_ARCHS=()
for arch in "${!LEGACY_FOR_ARCH[@]}"; do
  LEGACY_FILES+=("${LEGACY_FOR_ARCH[$arch]}")
  LEGACY_ARCHS+=("$arch")
  IS_LEGACY["${LEGACY_FOR_ARCH[$arch]}"]=1
done
ORPHAN_FILES=()
for FILE in "${FILES[@]}"; do
  [[ -n "${IS_LEGACY[$FILE]+set}" ]] || ORPHAN_FILES+=("$FILE")
done

refresh_pulp_token
LEGACY_TASKS=()
for FILE in "${LEGACY_FILES[@]}"; do
  assert_not_in_stable "$FILE"
  echo "[INFO] Uploading $FILE to $POOL_PATH/ ($SUITE/main, module $MODULE_NAME) [legacy path]"
  LEGACY_TASKS+=("$(
    pulp_upload \
      -F "file=@\"$FILE\"" \
      -F "relative_path=$POOL_PATH/$FILE" \
      -F "distribution=$SUITE" \
      -F "component=main" \
      -F "repository=$REPOSITORY_HREF" \
      -F "pulp_labels=$PULP_LABELS" \
      "$PULP_URL/api/v3/content/deb/packages/"
  )")
done
echo "[INFO] Waiting for ${#LEGACY_TASKS[@]} legacy upload task(s)"
wait_tasks "${LEGACY_TASKS[@]}"

# the release component href of $SUITE/main, deduced from the association the
# legacy uploads just created. A FRESH representative now carries exactly one
# association; a reused one carries its prior associations too, so the href is
# the difference between its post- and pre-upload association sets.
refresh_pulp_token
RELEASE_COMPONENT_HREF=""
for i in "${!LEGACY_FILES[@]}"; do
  FILE=${LEGACY_FILES[$i]}
  arch=${LEGACY_ARCHS[$i]}
  sha=$(sha256sum "$FILE" | cut -d' ' -f1)
  href=$(lookup_deb_content "packages" "--data-urlencode sha256=$sha")
  if [[ -z "$href" ]]; then
    echo "::error::Cannot find the legacy-delivered package $FILE (sha256 $sha)"
    exit 1
  fi
  after=$(lookup_prcs "$href" | sort)
  if [[ -n "${LEGACY_FRESH[$arch]+set}" ]]; then
    if [[ $(echo "$after" | grep -c .) -eq 1 ]]; then
      RELEASE_COMPONENT_HREF="$after"
      break
    fi
  else
    new_rcs=$(comm -13 <(echo "${LEGACY_BEFORE[$arch]}") <(echo "$after") | grep . || true)
    if [[ $(echo "$new_rcs" | grep -c .) -eq 1 ]]; then
      RELEASE_COMPONENT_HREF="$new_rcs"
      break
    elif [[ $(echo "$after" | grep -c .) -eq 1 ]]; then
      # rerun of a partially delivered leg: the association was created by
      # the previous attempt (empty diff) and is the only one the
      # representative carries - it IS the suite release component.
      RELEASE_COMPONENT_HREF=$(echo "$after" | grep .)
      break
    fi
  fi
done
if [[ -z "$RELEASE_COMPONENT_HREF" ]]; then
  echo "::error::Cannot deduce the $SUITE/main release component: every legacy representative is reused content whose suite association pre-exists. Deliver a rebuilt (fresh) package or clean up the previous partial delivery."
  exit 1
fi
echo "[INFO] Release component of $SUITE/main: $RELEASE_COMPONENT_HREF"

# parallel repository-less uploads (pool of 8), marker-file based like rpm
UPLOAD_DIR=$(mktemp -d)
MAX_PARALLEL_UPLOADS=8
for i in "${!ORPHAN_FILES[@]}"; do
  FILE=${ORPHAN_FILES[$i]}
  if ((i % 40 == 0)); then
    refresh_pulp_token
  fi
  (
    # subshell-local refresh: under server slowdowns the inherited token can
    # outlive its validity between two parent refreshes
    refresh_pulp_token
    assert_not_in_stable "$FILE"
    echo "[INFO] Uploading $FILE to $POOL_PATH/ ($SUITE/main, module $MODULE_NAME)"
    pulp_upload \
      -F "file=@\"$FILE\"" \
      -F "relative_path=$POOL_PATH/$FILE" \
      -F "pulp_labels=$PULP_LABELS" \
      "$PULP_URL/api/v3/content/deb/packages/" > "$UPLOAD_DIR/$i.task"
  ) &
  while (($(jobs -rp | wc -l) >= MAX_PARALLEL_UPLOADS)); do
    wait -n || true
  done
done
wait || true

echo "[INFO] Resolving ${#ORPHAN_FILES[@]} uploaded package(s)"
ORPHAN_SHA256S=()
for i in "${!ORPHAN_FILES[@]}"; do
  FILE=${ORPHAN_FILES[$i]}
  if [[ ! -s "$UPLOAD_DIR/$i.task" ]]; then
    echo "::error::Upload failed for $FILE (no task href, see the worker error above)"
    exit 1
  fi
  ORPHAN_SHA256S+=("$(sha256sum "$FILE" | cut -d' ' -f1)")
done
for i in "${!ORPHAN_FILES[@]}"; do
  if ((i % 40 == 0)); then
    refresh_pulp_token
  fi
  (
    resolve_task_content "$(cat "$UPLOAD_DIR/$i.task")" "packages" \
      "--data-urlencode sha256=${ORPHAN_SHA256S[$i]}" > "$UPLOAD_DIR/$i.content"
  ) &
  while (($(jobs -rp | wc -l) >= MAX_PARALLEL_UPLOADS)); do
    wait -n || true
  done
done
wait || true
PACKAGE_HREFS=()
for i in "${!ORPHAN_FILES[@]}"; do
  if [[ ! -s "$UPLOAD_DIR/$i.content" ]]; then
    echo "::error::Cannot resolve the uploaded content for ${ORPHAN_FILES[$i]} (see the worker error above)"
    exit 1
  fi
  PACKAGE_HREFS+=("$(cat "$UPLOAD_DIR/$i.content")")
done

# associate every uploaded package with the suite component. The
# package_release_components create is a plain synchronous DRF create (201
# with the created unit, no task), so the href comes straight out of the
# response; a failed create (unit already existing on a job re-run) falls
# back to a lookup.
echo "[INFO] Associating ${#PACKAGE_HREFS[@]} package(s) with $SUITE/main"
for i in "${!PACKAGE_HREFS[@]}"; do
  if ((i % 40 == 0)); then
    refresh_pulp_token
  fi
  (
    refresh_pulp_token
    response=$(
      curl -sSL --retry 3 --retry-delay 5 -w '\n%{http_code}' -H "Authorization: Github $PULP_TOKEN" \
        -X POST -H "Content-Type: application/json" \
        -d "{\"package\": \"${PACKAGE_HREFS[$i]}\", \"release_component\": \"$RELEASE_COMPONENT_HREF\"}" \
        "$PULP_URL/api/v3/content/deb/package_release_components/"
    ) || response=$'\n000'
    code="${response##*$'\n'}"
    body="${response%$'\n'*}"
    href=""
    [[ "$code" == 2* ]] && href=$(echo "$body" | jq -r '.pulp_href // .task // empty')
    if [[ -z "$href" ]]; then
      href=$(lookup_deb_content "package_release_components" \
        "--data-urlencode package=${PACKAGE_HREFS[$i]} --data-urlencode release_component=$RELEASE_COMPONENT_HREF")
      if [[ -n "$href" ]]; then
        # the api answers 500 on a duplicate synchronous content create; on a
        # rerun the association simply pre-exists, nothing is wrong
        echo "[INFO] ${ORPHAN_FILES[$i]}: suite association already exists (HTTP $code on create, expected on a rerun), reusing it"
      else
        echo "[WARN] Suite association create for ${ORPHAN_FILES[$i]} returned HTTP $code: $(echo "$body" | head -c 300)" >&2
      fi
    fi
    printf '%s' "$href" > "$UPLOAD_DIR/$i.prc"
  ) &
  while (($(jobs -rp | wc -l) >= MAX_PARALLEL_UPLOADS)); do
    wait -n || true
  done
done
wait || true

PRC_HREFS=()
for i in "${!PACKAGE_HREFS[@]}"; do
  href=""
  [[ -s "$UPLOAD_DIR/$i.prc" ]] && href=$(cat "$UPLOAD_DIR/$i.prc")
  if [[ "$href" == */tasks/* ]]; then
    href=$(resolve_task_content "$href" "package_release_components" \
      "--data-urlencode package=${PACKAGE_HREFS[$i]} --data-urlencode release_component=$RELEASE_COMPONENT_HREF")
  fi
  if [[ -z "$href" ]]; then
    echo "::error::Suite association failed for ${ORPHAN_FILES[$i]} (see the worker error above)"
    exit 1
  fi
  PRC_HREFS+=("$href")
done
rm -rf "$UPLOAD_DIR"

if ((${#PACKAGE_HREFS[@]} > 0)); then
  echo "[INFO] Adding ${#PACKAGE_HREFS[@]} package(s) and their suite associations to $REPOSITORY_NAME in a single task"
  refresh_pulp_token
  # body through a file: thousands of hrefs exceed the argv limit
  ADD_BODY_FILE=$(mktemp)
  printf '%s\n' "${PACKAGE_HREFS[@]}" "${PRC_HREFS[@]}" | jq -R . | jq -cs '{add_content_units: .}' > "$ADD_BODY_FILE"
  MODIFY_TASK=$(start_modify_task "$PULP_URL${REPOSITORY_HREF}modify/" "$ADD_BODY_FILE")
  wait_task "$MODIFY_TASK"
fi

# record every delivered package in the manifest for the verification step
for FILE in "${FILES[@]}"; do
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
create_publication deb "$REPOSITORY_NAME" --structured

echo "::notice::Packages are available with: deb $PULP_CONTENT_URL/$BASE_PATH/ $SUITE main"

manifest_write "$MODULE_NAME" "${DISTRIB:-}" "deb" "${STABILITY:-}" "delivery" "$PULP_CONTENT_URL"
