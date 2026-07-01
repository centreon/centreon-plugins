#!/bin/sh
touch /tmp/docker.ready
echo "Centreon VMware connector is ready"

exec "$@"
