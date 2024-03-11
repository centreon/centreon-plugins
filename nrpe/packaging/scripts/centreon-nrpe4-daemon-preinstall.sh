#!/bin/sh

getent group centreon-engine > /dev/null 2>&1 || groupadd -r centreon-engine
getent passwd centreon-engine > /dev/null 2>&1 || useradd -g centreon-engine --shell /bin/bash -m -d /var/lib/centreon-engine -r centreon-engine > /dev/null 2>&1 ||:
mkdir -p /var/lib/centreon/centplugins/
chown centreon-engine: /var/lib/centreon/centplugins/
