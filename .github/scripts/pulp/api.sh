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
# under set -e; the 600-attempt cap bounds the total wait (~30 min): under a
# full-matrix delivery the publication of a large repository can sit several
# minutes in the worker queue before its ~5 min of actual execution.
wait_task() {
  local task_href=$1
  local state attempt
  for ((attempt = 0; attempt < 600; attempt++)); do
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
  echo "::error::Task $task_href did not complete in time (~30 min)"
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

# wait for a task, distinguishing a RETRYABLE failure from a genuine one:
# - lost repository-version race: concurrent legs of a SHARED deb repository
#   collide on the version bookkeeping (duplicate (repository_id, number)
#   insert, or the retention cleanup deleting a version another transaction
#   still references)
# - "Worker has gone missing": the task worker pod was terminated mid-task
#   (scale-down, node consolidation)
# Re-running the operation converges, so callers retry on rc 2.
# 0=completed, 2=retryable failure, 1=failed or timed out.
wait_task_race() {
  local task_href=$1 body state error attempt
  for ((attempt = 0; attempt < 600; attempt++)); do
    refresh_pulp_token
    body=$(curl -fsSL -H "Authorization: Github $PULP_TOKEN" "$PULP_URL$task_href" 2>/dev/null) || body=""
    state=$(echo "$body" | jq -r '.state' 2>/dev/null) || state=""
    case "$state" in
      completed)
        return 0
        ;;
      failed | canceled)
        error=$(echo "$body" | jq -c '.error // empty' 2>/dev/null) || error=""
        if echo "$error" | grep -qE 'core_repositoryversion|Worker has gone missing'; then
          return 2
        fi
        # the "gone missing" reason lands in a separate field on some tasks
        if echo "$body" | jq -r '.reason // empty' 2>/dev/null | grep -q 'Worker has gone missing'; then
          return 2
        fi
        echo "::error::Task $task_href $state: $error"
        return 1
        ;;
      *)
        sleep 3
        ;;
    esac
  done
  echo "::error::Task $task_href did not complete in time (~30 min)"
  return 1
}

# POST a json body with MANUAL retry on transient gateway failures: curl
# --retry concatenates the bodies of failed attempts, which corrupts a
# captured json response (a 502 html page glued before the 201 body). A 500
# is NOT retried: on this api it means a duplicate synchronous content
# create, and the caller's lookup fallback is the correct answer.
# Echoes the final body; POST_HTTP_CODE holds the final status; rc 0 on 2xx.
post_json() {
  local url=$1 json=$2 attempt response
  response=""
  for attempt in 1 2 3 4; do
    refresh_pulp_token
    response=$(curl -sS -H "Authorization: Github $PULP_TOKEN" -w $'\n%{http_code}' \
      -X POST -H "Content-Type: application/json" -d "$json" "$url" 2>/dev/null) || response=$'\n000'
    POST_HTTP_CODE="${response##*$'\n'}"
    case "$POST_HTTP_CODE" in
      2* | 4* | 500) break ;;
      *) sleep $((attempt * 3)) ;;
    esac
  done
  printf '%s' "${response%$'\n'*}"
  [[ "$POST_HTTP_CODE" == 2* ]]
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
  local out task attempt outer rc
  # outer retry: the publication task itself can die server-side for
  # retryable reasons (task worker terminated mid-task, version race)
  for outer in 1 2 3; do
    task=""
    for attempt in 1 2 3; do
      refresh_pulp_token
      if out=$(pulp --background "$plugin" publication create --repository "$repository" "$@" 2>&1); then
        # an output without a task href (gateway error page relayed by the
        # cli) is a start failure too, retried like a non-zero exit
        task=$(grep -oPm1 '/api/v3/tasks/[0-9a-f-]+/' <<< "$out" || true)
        [[ -n "$task" ]] && break
      fi
      echo "[WARN] publication start attempt $attempt/3 failed for $repository, retrying..." >&2
      sleep $((attempt * 10))
    done
    if [[ -z "$task" ]]; then
      echo "::error::Cannot start the publication of repository $repository"
      return 1
    fi
    wait_task_race "$task" && rc=0 || rc=$?
    if [[ $rc -eq 0 ]]; then
      return 0
    elif [[ $rc -eq 2 && $outer -lt 3 ]]; then
      echo "[WARN] Publication of $repository was interrupted server-side, retrying"
      sleep $((outer * 15))
    else
      echo "::error::Publication of repository $repository failed"
      return 1
    fi
  done
}
