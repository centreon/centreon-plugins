#!/usr/bin/env bash
# Shared pulp api helpers for the delivery/promotion scripts. Source this file
# like manifest.sh; PULP_URL and PULP_TOKEN must be set by the caller.

# the github actions oidc token expires ~5 minutes after issuance, which is
# shorter than a large delivery: refresh it before it goes stale whenever the
# job can mint tokens (id-token: write context + audience exported by
# setup-pulp-cli). The fresh token is propagated to the following steps
# (GITHUB_ENV) and to the pulp-cli config so the pulp commands keep working.
refresh_pulp_token() {
  local now token
  now=$(date +%s)
  if ((now - ${PULP_TOKEN_ISSUED_AT:-0} < 240)); then
    return 0
  fi
  if [[ -z "${ACTIONS_ID_TOKEN_REQUEST_URL:-}" || -z "${ACTIONS_ID_TOKEN_REQUEST_TOKEN:-}" || -z "${PULP_OIDC_AUDIENCE:-}" ]]; then
    return 0
  fi
  token=$(
    curl -fsSL --retry 5 --retry-delay 3 --retry-all-errors \
      -H "Authorization: bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" \
      -G --data-urlencode "audience=$PULP_OIDC_AUDIENCE" \
      "$ACTIONS_ID_TOKEN_REQUEST_URL" 2>/dev/null | jq -r '.value' 2>/dev/null
  ) || token=""
  if [[ -z "$token" || "$token" == "null" ]]; then
    return 0
  fi
  PULP_TOKEN="$token"
  PULP_TOKEN_ISSUED_AT="$now"
  # written to stderr: this function also runs inside command substitutions
  # (pulp_upload), where a stdout echo would corrupt the captured output
  echo "::add-mask::$token" >&2
  if [[ -n "${GITHUB_ENV:-}" ]]; then
    {
      echo "PULP_TOKEN=$token"
      echo "PULP_TOKEN_ISSUED_AT=$now"
    } >> "$GITHUB_ENV"
  fi
  if command -v pulp >/dev/null 2>&1; then
    pulp config create --overwrite --base-url "$PULP_URL" --api-root "/" \
      --header "Authorization:Github $token" --timeout 0 >/dev/null 2>&1 || true
  fi
}

# wait for a pulp api task to complete. a failed poll request (network blip,
# api 5xx) is retried like an unexpected state instead of aborting the caller
# under set -e; the 200-attempt cap bounds the total wait (~10 min).
wait_task() {
  local task_href=$1
  local state attempt
  for ((attempt = 0; attempt < 200; attempt++)); do
    refresh_pulp_token
    state=$(curl -fsSL -H "Authorization: Github $PULP_TOKEN" "$PULP_URL$task_href" 2>/dev/null | jq -r '.state' 2>/dev/null) || state=""
    case "$state" in
      completed)
        return 0
        ;;
      failed|canceled)
        echo "::error::Task $task_href $state: $(curl -fsSL -H "Authorization: Github $PULP_TOKEN" "$PULP_URL$task_href" | jq -c '.error')"
        return 1
        ;;
      *)
        sleep 3
        ;;
    esac
  done
  echo "::error::Task $task_href did not complete in time (~10 min)"
  return 1
}

# wait for a batch of pulp api tasks, polling the still-pending ones in sweeps.
# unlike wait_task, the guard aborts only when NO task completes for ~10 min:
# tasks of a repository are serialized server-side, so a long-but-draining
# queue is expected under concurrent deliveries and must not be mistaken for a
# hang.
wait_tasks() {
  local pending=("$@")
  local total=$#
  local next=() stall=0 state href now last_report
  last_report=$(date +%s)
  while ((${#pending[@]} > 0)); do
    refresh_pulp_token
    next=()
    for href in "${pending[@]}"; do
      state=$(curl -fsSL -H "Authorization: Github $PULP_TOKEN" "$PULP_URL$href" 2>/dev/null | jq -r '.state' 2>/dev/null) || state=""
      case "$state" in
        completed) ;;
        failed|canceled)
          echo "::error::Task $href $state: $(curl -fsSL -H "Authorization: Github $PULP_TOKEN" "$PULP_URL$href" | jq -c '.error')"
          return 1
          ;;
        *)
          next+=("$href")
          ;;
      esac
    done
    if ((${#next[@]} == ${#pending[@]})); then
      stall=$((stall + 1))
      if ((stall >= 200)); then
        echo "::error::${#pending[@]} task(s) still pending with no progress for ~10 min, e.g. ${pending[0]}"
        return 1
      fi
    else
      stall=0
    fi
    pending=("${next[@]+"${next[@]}"}")
    # progress heartbeat, at most every 30s: shows how fast the server queue
    # drains (sweeps over large batches can take minutes on their own)
    now=$(date +%s)
    if ((${#pending[@]} > 0 && now - last_report >= 30)); then
      echo "[INFO] $((total - ${#pending[@]}))/$total task(s) completed"
      last_report=$now
    fi
    if ((${#pending[@]} > 0)); then
      sleep 3
    fi
  done
}

# upload a package through the pulp api, with retry on transient failures
# (concurrent deliveries can race on artifact creation), echoes the task href
pulp_upload() {
  local attempt response http_code body
  for attempt in 1 2 3 4 5; do
    refresh_pulp_token
    response=$(curl -sS -H "Authorization: Github $PULP_TOKEN" -w $'\n%{http_code}' "$@" 2>/dev/null) || response=""
    http_code=${response##*$'\n'}
    body=${response%$'\n'*}
    if [[ "$http_code" == "202" ]]; then
      echo "$body" | jq -r '.task'
      return 0
    fi
    echo "[WARN] upload attempt $attempt/5 failed (HTTP ${http_code:-network-error}), retrying..." >&2
    sleep $((attempt * 5))
  done
  echo "::error::Upload failed after 5 attempts (HTTP ${http_code:-network-error})" >&2
  return 1
}

# start a repository modify task, with retry on transient gateway failures:
# it is the single most critical call of the flow (all uploaded content lands
# in the repository through it) and add_content_units is idempotent, so
# retrying is always safe. Echoes the task href.
start_modify_task() {
  local url=$1 body_file=$2 attempt response http_code body
  for attempt in 1 2 3 4 5; do
    refresh_pulp_token
    response=$(curl -sS -H "Authorization: Github $PULP_TOKEN" -w $'\n%{http_code}' \
      -X POST -H "Content-Type: application/json" \
      -d @"$body_file" "$url" 2>/dev/null) || response=""
    http_code=${response##*$'\n'}
    body=${response%$'\n'*}
    if [[ "$http_code" == "202" ]]; then
      echo "$body" | jq -r '.task'
      return 0
    fi
    echo "[WARN] modify attempt $attempt/5 on $url failed (HTTP ${http_code:-network-error}), retrying..." >&2
    sleep $((attempt * 5))
  done
  echo "::error::Repository modify failed after 5 attempts on $url (HTTP ${http_code:-network-error}): $(echo "$body" | head -c 300)" >&2
  return 1
}

# create a publication in the background and wait for it with re-authenticating
# polling: pulp-cli reads its token once at startup, so its built-in wait fails
# with "Authentication failed for tasks_read" as soon as the publication of a
# large repository outlives the OIDC token validity (~5 minutes)
# curl against the content endpoint with the CI credentials: the guarded
# *business-internal distributions authorize the download through the same
# GitHub OIDC authentication as the api (the CI user holds the guard
# downloader role); unguarded distributions ignore the header.
content_curl() {
  refresh_pulp_token
  curl -H "Authorization: Github $PULP_TOKEN" "$@"
}

create_publication() {
  local plugin=$1 repository=$2
  shift 2
  local out task attempt
  for attempt in 1 2 3; do
    refresh_pulp_token
    out=$(pulp --background "$plugin" publication create --repository "$repository" "$@" 2>&1) && break
    echo "[WARN] publication start attempt $attempt/3 failed for $repository, retrying..." >&2
    sleep $((attempt * 10))
    out=""
  done
  if [[ -z "$out" ]]; then
    echo "::error::Cannot start the publication of repository $repository"
    return 1
  fi
  task=$(grep -oPm1 '/api/v3/tasks/[0-9a-f-]+/' <<< "$out" || true)
  if [[ -z "$task" ]]; then
    echo "$out"
    echo "::error::Cannot find the publication task of repository $repository in the pulp-cli output"
    return 1
  fi
  wait_task "$task"
}
