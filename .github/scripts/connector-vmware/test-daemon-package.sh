#!/bin/bash
# Install, launch and uninstall the VMware connector daemon package.
#
# The VMware Perl SDK is proprietary and cannot be installed in the CI: it is
# replaced by the stubs from tests/connectors/vmware, and the daemon is
# launched without any vCenter, so only the daemon itself is tested.
#
# Must be run as root from the repository root, in a disposable "testing" container
# (the Centreon repositories are already configured), with the package to test
# in the current directory.
#
# Required environment variables:
#   PACKAGE_EXTENSION    Package extension (rpm or deb)
set -euo pipefail

DAEMON_PORT=5700
TEST_DIR=$(mktemp -d)
chmod 755 "$TEST_DIR"
SYSTEMCTL_LOG="$TEST_DIR/systemctl.log"
DAEMON_LOG="$TEST_DIR/centreon_vmware.log"

fail() {
  echo "ERROR: $*"
  [[ -s "$DAEMON_LOG" ]] && { echo "=== Daemon log ==="; cat "$DAEMON_LOG"; }
  exit 1
}

echo "=== Prepare the system ==="
# runuser is not installed in all base images (e.g. almalinux:10)
[[ "$PACKAGE_EXTENSION" == "rpm" ]] && dnf install -y util-linux
# The postinstall script gives the configuration file to centreon-gorgone:centreon.
# On a real poller, these users are created by the Centreon packages.
getent group centreon >/dev/null || groupadd -r centreon
id centreon >/dev/null 2>&1 || useradd -r -M -g centreon -s /bin/bash centreon
getent group centreon-gorgone >/dev/null || groupadd -r centreon-gorgone
id centreon-gorgone >/dev/null 2>&1 || useradd -r -M -g centreon-gorgone -G centreon -s /bin/bash centreon-gorgone
# systemd is not running in the container: replace systemctl to record the calls of the postinstall script.
# It is never restored (disposable container), so the uninstall step does not exercise the real
# stop/disable scriptlets either.
cat > /usr/bin/systemctl <<EOF
#!/bin/sh
echo "\$*" >> "$SYSTEMCTL_LOG"
EOF
chmod 755 /usr/bin/systemctl

PACKAGE_FILES=(./*."$PACKAGE_EXTENSION")
[[ ${#PACKAGE_FILES[@]} -eq 1 && -f "${PACKAGE_FILES[0]}" ]] || fail "Expected exactly one .$PACKAGE_EXTENSION file, found: ${PACKAGE_FILES[*]}"
PACKAGE_FILE="${PACKAGE_FILES[0]}"

# The daemon is used through the VMware connector plugin, which brings the common Perl dependencies
# of the plugins. Only these dependencies are installed (read from the plugins packaging template),
# so that the test does not depend on the plugin version available in the repositories.
echo "=== Install the common Perl dependencies of the plugins ==="
mapfile -t COMMON_DEPENDENCIES < <(
  awk -v pkg="$PACKAGE_EXTENSION" '
    $0 == "  " pkg ":" { in_pkg = 1; next }
    in_pkg && /depends: \[/ { in_deps = 1; next }
    in_deps && /\]/ { exit }
    in_deps { gsub(/[ ,]/, ""); if ($0 != "" && $0 !~ /^@/) print }
  ' .github/packaging/centreon-plugin.yaml.template
)
[[ ${#COMMON_DEPENDENCIES[@]} -gt 0 ]] || fail "No common dependencies found in the plugins packaging template"
if [[ "$PACKAGE_EXTENSION" == "rpm" ]]; then
  dnf install -y --setopt=install_weak_deps=False "${COMMON_DEPENDENCIES[@]}"
else
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y --no-install-recommends "${COMMON_DEPENDENCIES[@]}"
fi

echo "=== Install $PACKAGE_FILE ==="
if [[ "$PACKAGE_EXTENSION" == "rpm" ]]; then
  PACKAGE_NAME=$(rpm -qp --queryformat '%{NAME}' "$PACKAGE_FILE")
  dnf install -y "$PACKAGE_FILE"
  rpm -q "$PACKAGE_NAME"
else
  PACKAGE_NAME=$(dpkg-deb -f "$PACKAGE_FILE" Package)
  apt-get install -y "$PACKAGE_FILE"
  dpkg -s "$PACKAGE_NAME" | grep -q '^Status: install ok installed' || fail "$PACKAGE_NAME is not correctly installed"
fi
grep -q 'restart centreon_vmware.service' "$SYSTEMCTL_LOG" || fail "The postinstall script did not restart the service"

echo "=== Launch the daemon ==="
cp -r tests/connectors/vmware/VMware "$TEST_DIR/"
cat > "$TEST_DIR/centreon_vmware.json" <<EOF
{
  "port": $DAEMON_PORT,
  "ipc_file": "$TEST_DIR/ipc/routing.ipc",
  "vsphere_server": []
}
EOF
chown -R centreon:centreon "$TEST_DIR"
DAEMON_OPTIONS=(--config-extra="$TEST_DIR/centreon_vmware.json" --logfile="$DAEMON_LOG" --severity=info)

# --check-config loads all the daemon modules, then exits
runuser -u centreon -- env PERL5LIB="$TEST_DIR" perl /usr/bin/centreon_vmware.pl "${DAEMON_OPTIONS[@]}" --check-config \
  || fail "The configuration check failed"

runuser -u centreon -- env PERL5LIB="$TEST_DIR" perl /usr/bin/centreon_vmware.pl "${DAEMON_OPTIONS[@]}" &
DAEMON_PID=$!
# Wait for the daemon's own log line: a connection check could succeed on a foreign listener
for i in $(seq 1 30); do
  grep -qF '[Server accepting clients]' "$DAEMON_LOG" 2>/dev/null && break
  kill -0 "$DAEMON_PID" 2>/dev/null || fail "The daemon stopped before accepting clients"
  sleep 1
done
grep -qF '[Server accepting clients]' "$DAEMON_LOG" || fail "The daemon is not accepting clients"
# The daemon does not check the result of zmq_bind: make sure the port is really open
perl -MIO::Socket::INET -e "exit(IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => $DAEMON_PORT, Timeout => 1) ? 0 : 1)" \
  || fail "The daemon is not listening on port $DAEMON_PORT"
echo "The daemon is accepting clients on port $DAEMON_PORT"

# Stop it (runuser forwards SIGTERM to the daemon): the main loop checks the stop flag every 5 seconds
kill -TERM "$DAEMON_PID"
for i in $(seq 1 30); do
  kill -0 "$DAEMON_PID" 2>/dev/null || break
  sleep 1
done
kill -0 "$DAEMON_PID" 2>/dev/null && fail "The daemon did not stop"
grep -qF 'Quit main process' "$DAEMON_LOG" || fail "The daemon did not stop cleanly"
echo "The daemon has stopped"

echo "=== Uninstall $PACKAGE_NAME ==="
if [[ "$PACKAGE_EXTENSION" == "rpm" ]]; then
  dnf remove -y "$PACKAGE_NAME"
  rpm -q "$PACKAGE_NAME" && fail "$PACKAGE_NAME is still installed"
else
  apt-get purge -y "$PACKAGE_NAME"
  dpkg -s "$PACKAGE_NAME" 2>/dev/null | grep -q '^Status: install' && fail "$PACKAGE_NAME is still installed"
fi
[[ -e /usr/bin/centreon_vmware.pl ]] && fail "/usr/bin/centreon_vmware.pl is still present"

echo "=== Test succeeded ==="
