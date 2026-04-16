#!/bin/bash

json_config_file_path='/etc/centreon/centreon_vmware.json'
perl_config_file_path='/etc/centreon/centreon_vmware.pm'

function migrateConfigFromPmToJson() {
    # If the legacy config file exists, we migrate it into a JSON config file
    if [[ -f "$perl_config_file_path" ]] ; then
        /usr/bin/centreon_vmware_convert_config_file "$perl_config_file_path" > "$json_config_file_path"
        mv "$perl_config_file_path" "${perl_config_file_path}.deprecated"
    fi
    chown centreon-gorgone:centreon "$json_config_file_path"
    chmod 660 "$json_config_file_path"
}

function applyToSystemD() {
    systemctl daemon-reload
    systemctl restart centreon_vmware.service
}

action="$1"
version="$2"

if  [[ "$1" == "configure" ]]; then # deb
    if  [[ -z "$version" ]]; then
        # Alpine linux does not pass args, and deb passes $1=configure
        action="install"
    elif [[ -n "$version" ]]; then
        # deb passes $1=configure $2=<current version>
        action="upgrade"
    fi
fi


case "$action" in
  "1" | "install")
    migrateConfigFromPmToJson
    applyToSystemD
    ;;
  "2" | "upgrade")
    migrateConfigFromPmToJson
    applyToSystemD
    ;;
  *)
    # $1 == version being installed
    applyToSystemD
    ;;
esac

