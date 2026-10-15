#!/usr/bin/env bash
# Tags the tip of a plugins release/hotfix branch with its release bundle tag (plugins-YYYYMMNN),
# then creates the draft github release, the CTOR jira version and deletes the branch.
# Every check runs before the first write; DRY_RUN=true (default) prints the writes instead.
set -euo pipefail

TAG_PREFIX="plugins"
JIRA_VERSION_PREFIX="centreon-plugins"
REMOTE="${REMOTE:-origin}"

RELEASE_BRANCH="${RELEASE_BRANCH:-}"
RELEASE_NUMBER="${RELEASE_NUMBER:-}"
RELEASE_TYPE="${RELEASE_TYPE:-}"
DRY_RUN="${DRY_RUN:-true}"
HAS_RELEASE_TOKEN="${HAS_RELEASE_TOKEN:-false}"
JIRA_BASE_URL="${JIRA_BASE_URL:-}"
JIRA_USER_EMAIL="${JIRA_USER_EMAIL:-}"
JIRA_API_TOKEN="${JIRA_API_TOKEN:-}"
JIRA_CTOR_PROJECT_ID="${JIRA_CTOR_PROJECT_ID:-}"

summary() {
  if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    echo "$*" >> "$GITHUB_STEP_SUMMARY"
  fi
}

fail() {
  echo "::error::$*" >&2
  summary "- :x: $*"
  exit 1
}

warn() {
  echo "::warning::$*" >&2
  summary "- :warning: $*"
}

info() {
  echo "$*"
  summary "- $*"
}

run() {
  if [[ "$DRY_RUN" == "true" ]]; then
    printf '[dry-run]'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

check_inputs() {
  [[ "$DRY_RUN" == "true" || "$DRY_RUN" == "false" ]] || fail "dry_run must be true or false (got '$DRY_RUN')."
  [[ -n "$RELEASE_BRANCH" && -n "$RELEASE_NUMBER" && -n "$RELEASE_TYPE" ]] || fail "release_branch, release_number and release_type are required."
  [[ "$RELEASE_NUMBER" =~ ^[0-9]{8}$ && "$RELEASE_NUMBER" != "00000000" ]] || fail "release_number must use YYYYMMNN format (got '$RELEASE_NUMBER')."
  [[ "$RELEASE_TYPE" == "release" || "$RELEASE_TYPE" == "hotfix" ]] || fail "release_type must be release or hotfix (got '$RELEASE_TYPE')."
  [[ "$RELEASE_BRANCH" =~ ^(release|hotfix)-([0-9]{8})$ ]] || fail "release_branch must be release-YYYYMMNN or hotfix-YYYYMMNN (got '$RELEASE_BRANCH')."
  [[ "${BASH_REMATCH[1]}" == "$RELEASE_TYPE" ]] || fail "release_type '$RELEASE_TYPE' does not match branch $RELEASE_BRANCH."
  [[ "${BASH_REMATCH[2]}" == "$RELEASE_NUMBER" ]] || fail "release_number $RELEASE_NUMBER does not match branch $RELEASE_BRANCH."
  [[ "${GITHUB_REF_NAME:-}" == "develop" ]] || fail "release-new must be dispatched from develop (got '${GITHUB_REF_NAME:-}')."
}

check_credentials() {
  local missing=()
  [[ "$HAS_RELEASE_TOKEN" == "true" ]] || missing+=("CENTREON_TECHNIQUE_PAT")
  [[ -n "$JIRA_BASE_URL" ]] || missing+=("JIRA_BASE_URL")
  [[ -n "$JIRA_USER_EMAIL" ]] || missing+=("JIRA_RELEASE_USER")
  [[ -n "$JIRA_API_TOKEN" ]] || missing+=("JIRA_RELEASE_TOKEN")
  [[ -n "$JIRA_CTOR_PROJECT_ID" ]] || missing+=("JIRA_CTOR_PROJECT_ID")
  if [[ -n "$JIRA_CTOR_PROJECT_ID" && ! "$JIRA_CTOR_PROJECT_ID" =~ ^[0-9]+$ ]]; then
    fail "JIRA_CTOR_PROJECT_ID must be a numeric jira project id."
  fi
  if (( ${#missing[@]} > 0 )); then
    if [[ "$DRY_RUN" == "true" ]]; then
      warn "secrets not available to this repository, a real run would fail: ${missing[*]}"
    else
      fail "secrets not available to this repository: ${missing[*]}"
    fi
  fi
}

check_branch() {
  git ls-remote --exit-code --heads "$REMOTE" "refs/heads/$RELEASE_BRANCH" > /dev/null \
    || fail "branch $RELEASE_BRANCH does not exist on $REMOTE."
  git fetch --quiet --depth=1 "$REMOTE" "+refs/heads/$RELEASE_BRANCH:refs/remotes/$REMOTE/$RELEASE_BRANCH"
  RELEASE_SHA="$(git rev-parse "refs/remotes/$REMOTE/$RELEASE_BRANCH^{commit}")"
  info "branch $RELEASE_BRANCH is at $RELEASE_SHA"
}

check_versions() {
  local file_version script_line script_version=""
  local script_re="^[[:space:]]*my[[:space:]]+\\\$global_version[[:space:]]*=[[:space:]]*['\"]([^'\"]*)['\"]"

  file_version="$(git show "$RELEASE_SHA:.version.plugins" | tr -d '[:space:]')"
  [[ "$file_version" == "$RELEASE_NUMBER" ]] \
    || fail ".version.plugins on $RELEASE_BRANCH is '$file_version', expected $RELEASE_NUMBER."

  script_line="$(git show "$RELEASE_SHA:src/centreon/plugins/script.pm" | grep -m 1 'global_version' || true)"
  if [[ "$script_line" =~ $script_re ]]; then
    script_version="${BASH_REMATCH[1]}"
  fi
  [[ "$script_version" == "$RELEASE_NUMBER" ]] \
    || fail "\$global_version in src/centreon/plugins/script.pm on $RELEASE_BRANCH is '$script_version', expected $RELEASE_NUMBER."

  info "versions are coherent: $RELEASE_NUMBER"
}

check_tags() {
  local rc=0 latest
  RELEASE_TAG="$TAG_PREFIX-$RELEASE_NUMBER"

  git ls-remote --exit-code --tags "$REMOTE" "refs/tags/$RELEASE_TAG" > /dev/null || rc=$?
  case "$rc" in
    0) fail "tag $RELEASE_TAG already exists." ;;
    2) ;;
    *) fail "cannot list tags of $REMOTE." ;;
  esac

  latest="$(git ls-remote --tags --refs "$REMOTE" "refs/tags/$TAG_PREFIX-*" \
    | sed 's#.*refs/tags/##' \
    | { grep -E "^$TAG_PREFIX-[0-9]{8}$" || true; } \
    | sort -V | tail -n 1)"
  if [[ -z "$latest" ]]; then
    warn "no previous $TAG_PREFIX-YYYYMMNN tag found."
  elif (( 10#$RELEASE_NUMBER <= 10#${latest#"$TAG_PREFIX-"} )); then
    fail "release_number $RELEASE_NUMBER must be greater than latest release tag $latest."
  else
    info "previous release tag is $latest"
  fi
}

create_tag() {
  info "tagging $RELEASE_SHA ($RELEASE_BRANCH) with $RELEASE_TAG: \"$RELEASE_TYPE $RELEASE_TAG\""
  run git -c user.name="Centreon" -c user.email="release@centreon.com" \
    tag -a "$RELEASE_TAG" -m "$RELEASE_TYPE $RELEASE_TAG" "$RELEASE_SHA"
  run git push --quiet "$REMOTE" "refs/tags/$RELEASE_TAG"
}

create_github_release() {
  info "creating draft github release $RELEASE_TAG"
  run gh release create "$RELEASE_TAG" --draft --verify-tag --title "$RELEASE_TAG" --notes ""
}

create_jira_version() {
  local name="$JIRA_VERSION_PREFIX-$RELEASE_NUMBER" payload credentials
  payload="$(jq -nc \
    --arg name "$name" \
    --arg projectId "${JIRA_CTOR_PROJECT_ID:-0}" \
    --arg description "$RELEASE_TYPE $RELEASE_TAG" \
    --arg releaseDate "$(date +%Y-%m-%d)" \
    '{name: $name, projectId: ($projectId | tonumber), description: $description, releaseDate: $releaseDate, released: false, archived: false}')"

  info "creating jira version $name"
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[dry-run] POST ${JIRA_BASE_URL:-<JIRA_BASE_URL>}/rest/api/3/version $payload"
    return
  fi

  # credentials go through a curl config on a file descriptor to keep them out of argv
  credentials="$JIRA_USER_EMAIL:$JIRA_API_TOKEN"
  credentials="${credentials//\\/\\\\}"
  credentials="${credentials//\"/\\\"}"
  curl --fail-with-body --silent --show-error --request POST \
    --url "$JIRA_BASE_URL/rest/api/3/version" \
    --config <(printf 'user = "%s"\n' "$credentials") \
    --header 'Accept: application/json' \
    --header 'Content-Type: application/json' \
    --data "$payload"
  echo
}

delete_branch() {
  local tagged_sha
  if [[ "$DRY_RUN" == "false" ]]; then
    tagged_sha="$(git ls-remote --tags "$REMOTE" "refs/tags/$RELEASE_TAG^{}" | cut -f 1)"
    [[ "$tagged_sha" == "$RELEASE_SHA" ]] \
      || fail "tag $RELEASE_TAG is not on $REMOTE at $RELEASE_SHA, keeping branch $RELEASE_BRANCH."
  fi

  info "deleting branch $RELEASE_BRANCH"
  # the lease refuses the deletion if the branch moved since it was tagged
  run git push --quiet --force-with-lease="refs/heads/$RELEASE_BRANCH:$RELEASE_SHA" \
    "$REMOTE" ":refs/heads/$RELEASE_BRANCH"
}

main() {
  if [[ "$DRY_RUN" == "true" ]]; then
    summary "## release-new (dry run: nothing is written)"
  else
    summary "## release-new"
  fi

  check_inputs
  check_credentials
  check_branch
  check_versions
  check_tags

  create_tag
  create_github_release
  create_jira_version
  delete_branch

  info "$RELEASE_TYPE $RELEASE_TAG done"
}

main "$@"
