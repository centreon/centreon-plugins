#!/usr/bin/env bash
# Resolves the stable context of a plugins-YYYYMMNN tag push (outputs: is_release_tag, version,
# release_type from the tag message, previous_tag, and changed: whether the calling workflow
# on.push.paths changed since the previous release tag).
set -euo pipefail

TAG_PREFIX="plugins"
TAG_NAME="${TAG_NAME:-}"
WORKFLOW_FILE="${WORKFLOW_FILE:-}"
GITHUB_OUTPUT="${GITHUB_OUTPUT:-/dev/stdout}"

output() {
  echo "$1=$2" >> "$GITHUB_OUTPUT"
}

summary() {
  if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    echo "$*" >> "$GITHUB_STEP_SUMMARY"
  fi
}

fail() {
  echo "::error::$*" >&2
  exit 1
}

# prints the workflow on.push.paths patterns, nothing if they cannot be read
workflow_push_paths() {
  if [[ -z "$WORKFLOW_FILE" || ! -f "$WORKFLOW_FILE" ]]; then
    echo "::warning::workflow file '$WORKFLOW_FILE' not found, considering every path as changed." >&2
    return
  fi
  if ! command -v yq > /dev/null 2>&1; then
    echo "::warning::yq is not available, considering every path as changed." >&2
    return
  fi
  yq -r '.on.push.paths // [] | .[]' "$WORKFLOW_FILE"
}

main() {
  local version release_type message tag_type previous_tag="" file_version changed="false"
  local -a patterns=() files=()

  if [[ ! "$TAG_NAME" =~ ^$TAG_PREFIX-([0-9]{8})$ ]]; then
    echo "$TAG_NAME is not a release tag."
    output is_release_tag false
    return
  fi
  version="${BASH_REMATCH[1]}"

  tag_type="$(git cat-file -t "refs/tags/$TAG_NAME" 2> /dev/null || true)"
  [[ "$tag_type" == "tag" ]] || fail "release tag $TAG_NAME must be an annotated tag (got '${tag_type:-missing}')."

  message="$(git for-each-ref --format='%(contents:subject)' "refs/tags/$TAG_NAME")"
  release_type="${message%% *}"
  [[ "$release_type" == "release" || "$release_type" == "hotfix" ]] \
    || fail "message of release tag $TAG_NAME must start with release or hotfix (got '$message')."

  file_version="$(git show "refs/tags/$TAG_NAME:.version.plugins" 2> /dev/null | tr -d '[:space:]' || true)"
  if [[ "$file_version" != "$version" ]]; then
    echo "::warning::.version.plugins is '$file_version' on $TAG_NAME, expected $version."
  fi

  while read -r tag; do
    if (( 10#${tag#"$TAG_PREFIX-"} < 10#$version )); then
      previous_tag="$tag"
    fi
  done < <(git tag -l "$TAG_PREFIX-*" | { grep -E "^$TAG_PREFIX-[0-9]{8}$" || true; } | sort -V)

  mapfile -t patterns < <(workflow_push_paths)
  if [[ -z "$previous_tag" ]]; then
    echo "::warning::no release tag before $TAG_NAME, considering every path as changed."
    changed="true"
  elif (( ${#patterns[@]} == 0 )); then
    changed="true"
  else
    mapfile -t files < <(git diff --name-only "refs/tags/$previous_tag" "refs/tags/$TAG_NAME")
    for file in "${files[@]}"; do
      for pattern in "${patterns[@]}"; do
        # unquoted pattern: glob match where * also spans /, so ** behaves like the workflow filter
        # shellcheck disable=SC2053
        if [[ "$file" == $pattern ]]; then
          echo "$file matches $pattern"
          changed="true"
          break 2
        fi
      done
    done
  fi

  echo "release tag $TAG_NAME: $release_type $version, previous release tag ${previous_tag:-none}, workflow paths changed: $changed"
  summary "Release tag \`$TAG_NAME\` ($release_type), previous release tag \`${previous_tag:-none}\`, workflow paths changed: $changed"
  output is_release_tag true
  output version "$version"
  output release_type "$release_type"
  output previous_tag "$previous_tag"
  output changed "$changed"
}

main "$@"
