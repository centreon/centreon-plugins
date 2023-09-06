#!/bin/sh

install() {
  semodule -i /usr/share/selinux/packages/centreon/centreon-plugins.pp > /dev/null 2>&1 || :
}

upgrade() {
  semodule -i /usr/share/selinux/packages/centreon/centreon-plugins.pp > /dev/null 2>&1 || :
}

action="$1"
if  [ "$1" = "configure" ] && [ -z "$2" ]; then
  # Alpine linux does not pass args, and deb passes $1=configure
  action="install"
elif [ "$1" = "configure" ] && [ -n "$2" ]; then
    # deb passes $1=configure $2=<current version>
    action="upgrade"
fi

case "$action" in
  "1" | "install")
    install
    ;;
  "2" | "upgrade")
    upgrade
    ;;
esac
