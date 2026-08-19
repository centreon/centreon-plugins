#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=.github/scripts/pulp/manifest.sh
source "$(dirname "$0")/../../scripts/pulp/manifest.sh"
# shellcheck source=.github/scripts/pulp/api.sh
source "$(dirname "$0")/../../scripts/pulp/api.sh"

# an unset org variable is forwarded as an empty string, overriding the default
PULP_URL="${PULP_URL:-https://pulp-api.apps.centreon.com}"
PULP_CONTENT_URL="${PULP_CONTENT_URL:-https://packages.apps.centreon.com}"
# stable shares its Domain with testing since the domain merge (PULP_STABLE_DOMAIN
# now equals PULP_DOMAIN); the read/write phase switch is kept as a no-op
PULP_DOMAIN="${PULP_DOMAIN:-default}"
PULP_STABLE_DOMAIN="${PULP_STABLE_DOMAIN:-default}"
# switch_pulp_domain overwrites PULP_DOMAIN itself once the write phase
# starts; keep our own copy for the testing-domain content-app fetch after that
TESTING_DOMAIN="$PULP_DOMAIN"

# re-applied on the re-upload into stable (this promote run's own git context,
# not the original delivery's); check-rpm.sh's verification query needs at
# least "module" to find the promoted content
PULP_LABELS=$(jq -cn \
  --arg mod        "$MODULE_NAME" \
  --arg git_commit "${GITHUB_SHA:-}" \
  --arg git_ref    "${GITHUB_REF:-}" \
  --arg run_id     "${GITHUB_RUN_ID:-}" \
  --arg actor      "${GITHUB_ACTOR:-}" \
  --arg workflow   "${GITHUB_WORKFLOW:-}" \
  '{"module": $mod, "git_commit": $git_commit, "git_ref": $git_ref, "github_run_id": $run_id, "github_actor": $actor, "github_workflow": $workflow}')

# mirrors deliver-rpm.sh's resolve_uploaded_content, scoped to the stable domain
resolve_promoted_content() {
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
      "$PULP_URL/$PULP_STABLE_DOMAIN/api/v3/content/rpm/packages/" | jq -r '.results[0].pulp_href // empty'
  )
  if [[ -z "$content" ]]; then
    echo "::error::Cannot resolve the promoted content for task $task_href (sha256 $sha256)" >&2
    return 1
  fi
  echo "$content"
}

# resolve a package's served location by sha256 (mirrors check-rpm.sh's
# resolve_href): pulp_rpm publishes under Packages/<letter>/<file>, which
# doesn't match the content API's location_href (the upload-time relative path)
resolve_rpm_href() {
  local primary_file=$1 sha=$2
  [[ -s "$primary_file" ]] || return 0
  awk -v sha="$sha" '
    BEGIN { RS = "</package>" }
    index($0, ">" sha "</checksum>") {
      if (match($0, /<location[^>]*href="[^"]+"/)) {
        s = substr($0, RSTART, RLENGTH)
        sub(/.*href="/, "", s); sub(/"$/, "", s)
        print s; exit
      }
    }' "$primary_file"
}

# fetch the published primary.xml for a base_path into $3 (a single fetch:
# promote processes one base_path per arch sequentially, unlike check-rpm.sh's
# many-packages-in-parallel caching)
fetch_primary_xml() {
  local domain=$1 base_path=$2 out=$3 repomd primary_href
  repomd=$(content_curl -fsSL "$PULP_CONTENT_URL/$domain/$base_path/repodata/repomd.xml" 2>/dev/null || true)
  primary_href=$(printf '%s' "$repomd" | grep -oP '<location href="\K[^"]+primary\.xml[^"]*' | head -1 || true)
  if [[ -n "$primary_href" ]]; then
    content_curl -fsSL "$PULP_CONTENT_URL/$domain/$base_path/$primary_href" 2>/dev/null | gunzip -c 2>/dev/null > "$out" || true
  fi
}

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
  TESTING_BASE_PATH="$TESTING_BASE_PATH_PREFIX/$ARCH"

  if ! pulp_resource_exists "repositories/rpm/rpm" "$STABLE_REPOSITORY_NAME"; then
    echo "::error::stable rpm repository $STABLE_REPOSITORY_NAME does not exist. Pulp repositories and distributions are provisioned centrally by delivery-tooling create-repos; run create-repos for this version before promoting."
    exit 1
  fi

  if ! pulp_resource_exists "distributions/rpm/rpm" "$STABLE_REPOSITORY_NAME"; then
    echo "::error::stable rpm distribution $STABLE_REPOSITORY_NAME does not exist. Pulp distributions are provisioned centrally by delivery-tooling create-repos; run create-repos for this version before promoting. Refusing to create it here to avoid an unguarded distribution."
    exit 1
  fi

  STABLE_REPOSITORY_HREF=$(pulp rpm repository show --name "$STABLE_REPOSITORY_NAME" | jq -r '.pulp_href')

  # Pulp Domains share no content across domains (RepositoryVersion.add_content
  # requires a matching pulp_domain), so promoting re-downloads each package
  # from testing's published distribution and re-uploads it into the stable
  # domain -- same as the JFrog promote job always did.
  echo "[INFO] Re-uploading $ARCH_PACKAGES_COUNT package(s) from $TESTING_BASE_PATH into the stable domain"
  DOWNLOAD_DIR=$(mktemp -d)
  UPLOAD_DIR=$(mktemp -d)
  MAX_PARALLEL_UPLOADS=8
  TESTING_PRIMARY_XML=$(mktemp)
  fetch_primary_xml "$TESTING_DOMAIN" "$TESTING_BASE_PATH" "$TESTING_PRIMARY_XML"
  mapfile -t PKG_ROWS < <(echo "$RESULTS" | jq -c '.[]')
  for i in "${!PKG_ROWS[@]}"; do
    if ((i % 40 == 0)); then
      refresh_pulp_token
    fi
    (
      refresh_pulp_token
      location_href=$(echo "${PKG_ROWS[$i]}" | jq -r '.location_href')
      sha256=$(echo "${PKG_ROWS[$i]}" | jq -r '.sha256')
      served_href=$(resolve_rpm_href "$TESTING_PRIMARY_XML" "$sha256")
      if [[ -z "$served_href" ]]; then
        echo "::error::Cannot resolve the published location of $(echo "${PKG_ROWS[$i]}" | jq -r '.name') (sha256 $sha256) in $TESTING_BASE_PATH" >&2
        exit 1
      fi
      dest="$DOWNLOAD_DIR/$i-$(basename "$location_href")"
      content_curl -fsSL --retry 3 --retry-delay 5 -o "$dest" "$PULP_CONTENT_URL/$TESTING_DOMAIN/$TESTING_BASE_PATH/$served_href"
      pulp_upload -F "file=@\"$dest\"" -F "pulp_labels=$PULP_LABELS" \
        "$PULP_URL/$PULP_STABLE_DOMAIN/api/v3/content/rpm/packages/" > "$UPLOAD_DIR/$i.task"
    ) &
    while (($(jobs -rp | wc -l) >= MAX_PARALLEL_UPLOADS)); do
      wait -n || true
    done
  done
  wait || true

  NEW_HREFS=()
  for i in "${!PKG_ROWS[@]}"; do
    if [[ ! -s "$UPLOAD_DIR/$i.task" ]]; then
      echo "::error::Re-upload into the stable domain failed for $(echo "${PKG_ROWS[$i]}" | jq -r '.name') ($ARCH), see the worker error above"
      exit 1
    fi
    new_href=$(resolve_promoted_content "$(cat "$UPLOAD_DIR/$i.task")" "$(echo "${PKG_ROWS[$i]}" | jq -r '.sha256')") || new_href=""
    if [[ -z "$new_href" ]]; then
      echo "::error::Cannot resolve the promoted content for $(echo "${PKG_ROWS[$i]}" | jq -r '.name') ($ARCH)"
      exit 1
    fi
    NEW_HREFS+=("$new_href")
  done
  rm -rf "$DOWNLOAD_DIR" "$UPLOAD_DIR"
  rm -f "$TESTING_PRIMARY_XML"
  CONTENT=$(printf '%s\n' "${NEW_HREFS[@]}" | jq -R . | jq -cs .)

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
