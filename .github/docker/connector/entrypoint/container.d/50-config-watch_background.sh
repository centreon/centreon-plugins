#!/bin/sh
# Restart container when centreon_vmware.json is updated.
# centreon_vmware.pl does not support SIGHUP config reload — the daemon (PID 1)
# is terminated so Docker restarts the container with the new configuration.
# Handles both in-place writes (close_write) and atomic replacements (moved_to/create).

CONFIG="/etc/centreon/centreon_vmware.json"
CONFIG_DIR=$(dirname "$CONFIG")
CONFIG_FILE=$(basename "$CONFIG")

echo "config-watch: monitoring ${CONFIG} for updates"

inotifywait -m -q -e close_write,moved_to,create --format '%f' "${CONFIG_DIR}" | \
while IFS= read -r filename; do
  [ "$filename" = "$CONFIG_FILE" ] || continue
  echo "config-watch: ${CONFIG_FILE} updated — restarting container (SIGTERM to PID 1)"
  kill -TERM 1
done
