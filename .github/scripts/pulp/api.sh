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
  echo "::add-mask::$token"
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
  for attempt in 1 2 3; do
    refresh_pulp_token
    response=$(curl -sS -H "Authorization: Github $PULP_TOKEN" -w $'\n%{http_code}' "$@" 2>/dev/null) || response=""
    http_code=${response##*$'\n'}
    body=${response%$'\n'*}
    if [[ "$http_code" == "202" ]]; then
      echo "$body" | jq -r '.task'
      return 0
    fi
    echo "[WARN] upload attempt $attempt/3 failed (HTTP ${http_code:-network-error}), retrying..." >&2
    sleep $((attempt * 3))
  done
  echo "::error::Upload failed after 3 attempts (HTTP ${http_code:-network-error})" >&2
  return 1
}
