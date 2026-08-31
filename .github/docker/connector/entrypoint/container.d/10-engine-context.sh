#!/bin/sh
# This file is sourced (not executed) by container.sh, so DEBUG=true's
# `set -x` is inherited here. Disable it before touching the secrets: with
# tracing on, the shell would print APP_SECRET/SALT's actual values inline
# (e.g. "+ APP_SECRET=...", "+ printf ... <secret>"). Restore it afterwards
# so later container.d scripts still get traced when DEBUG is enabled.
case "$-" in *x*) trace_was_on=1 ;; esac
set +x

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
    echo "Debug: $(ls -l "$ENGINE_CONTEXT")"
fi
echo ""

[ "$trace_was_on" = "1" ] && set -x
:
