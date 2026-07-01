#!/bin/sh
echo "=== Writing Engine Secrets ==="

APP_SECRET="${APP_SECRET:?ERROR: APP_SECRET must be set for poller mode}"
SALT="${SALT:?ERROR: SALT must be set for poller mode}"
ENGINE_CONTEXT="/etc/centreon-engine/engine-context.json"

# /etc/centreon-engine/ is group-writable (775, centreon-engine group).
# centreon user belongs to centreon-engine group — no root required.
printf '{"app_secret":"%s","salt":"%s"}\n' "$APP_SECRET" "$SALT" > "$ENGINE_CONTEXT"
chmod 640 "$ENGINE_CONTEXT"

echo "✓ Engine secrets written to $ENGINE_CONTEXT"
if [ "${DEBUG}" = "true" ] || [ "${DEBUG}" = "1" ]; then
    echo "Debug: $(cat "$ENGINE_CONTEXT")"
fi
echo ""
