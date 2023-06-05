#!/bin/sh

if  [ "$1" = "configure" ]; then # deb
  if [ ! -f "/etc/centreon/centreon_vmware.pm" ]; then
    mv /etc/centreon/centreon_vmware.pm.new /etc/centreon/centreon_vmware.pm
  fi
fi
