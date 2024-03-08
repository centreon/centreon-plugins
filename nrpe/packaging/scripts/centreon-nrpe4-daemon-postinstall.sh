#!/bin/sh

startNrpeDaemon() {
  systemctl daemon-reload ||:
  systemctl unmask centreon-nrpe4.service ||:
  systemctl preset centreon-nrpe4.service ||:
  systemctl enable centreon-nrpe4.service ||:
  systemctl restart centreon-nrpe4.service ||:
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
    startNrpeDaemon
    ;;
  "2" | "upgrade")
    startNrpeDaemon
    ;;
  *)
    # $1 == version being installed
    startNrpeDaemon
    ;;
esac
