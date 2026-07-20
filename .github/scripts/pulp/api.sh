#!/usr/bin/env bash
# Shared pulp api helpers for the delivery/promotion scripts. Source this file
# like manifest.sh; PULP_URL and PULP_TOKEN must be set by the caller.

# wait for a pulp api task to complete. a failed poll request (network blip,
# api 5xx) is retried like an unexpected state instead of aborting the caller
# under set -e; the 200-attempt cap bounds the total wait (~10 min).
wait_task() {
  local task_href=$1
  local state attempt
  for ((attempt = 0; attempt < 200; attempt++)); do
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

# upload a package through the pulp api, with retry on transient failures
# (concurrent deliveries can race on artifact creation), echoes the task href
pulp_upload() {
  local attempt response http_code body
  for attempt in 1 2 3; do
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
