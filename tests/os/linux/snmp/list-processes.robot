*** Settings ***
Documentation       Check arp table

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::linux::snmp::plugin


*** Test Cases ***
list-processes ${tc}
    [Tags]    os    linux
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-processes
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/linux/snmp/linux
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                   expected_result    --
            ...      1     --verbose                       OK: 
            ...      2     --filter-name='cbd'             List processes: [name = cbd] [path = /usr/sbin/cbd] [parameters = /etc/centreon-broker/central-broker.json] [type = application] [pid = 658] [status = runnable] [name = cbd] [path = /usr/sbin/cbd] [parameters = /etc/centreon-broker/central-rrd.json] [type = application] [pid = 659] [status = runnable]
            ...      3     --add-stats --help              List processes: [name = rcu_preempt] [path = ] [parameters = ] [type = operatingSystem] [pid = 15] [status = invalid] [name = gorgone-audit] [path = gorgone-audit] [parameters = ] [type = application] [pid = 756] [status = runnable] [name = apache2] [path = /usr/sbin/apache2] [parameters = -k start] [type = application] [pid = 2544] [status = runnable] [name = php-fpm8.1] [path = php-fpm: pool www] [parameters = ] [type = application] [pid = 577] [status = runnable] [name = php-fpm8.1] [path = php-fpm: pool www] [parameters = ] [type = application] [pid = 580] [status = runnable] [name = agetty] [path = /sbin/agetty] [parameters = -o -p -- \\u --noclear - linux] [type = application] [pid = 465] [status = runnable] [ Message content over the limit has been removed. ] ...ash] [parameters = ] [type = application] [pid = 1594] [status = runnable] [name = kworker/0:1-mm_percpu_wq] [path = ] [parameters = ] [type = operatingSystem] [pid = 1759] [status = invalid] [name = snmpd] [path = /usr/sbin/snmpd] [parameters = -LOw -u Debian-snmp -g Debian-snmp -I -smux mteTrigger mteTriggerConf -f] [type = application] [pid = 449] [status = running] [name = dhclient] [path = dhclient] [parameters = -4 -v -i -pf /run/dhclient.eth0.pid -lf /var/lib/dhcp/dhclient.eth0.leases -I -df /var/lib/dhcp/dhclient6.eth0.leases eth0] [type = application] [pid = 341] [status = runnable] [name = cbd] [path = /usr/sbin/cbd] [parameters = /etc/centreon-broker/central-broker.json] [type = application] [pid = 658] [status = runnable] [name = bash] [path = -bash] [parameters = ] [type = application] [pid = 3369] [status = runnable] [name = mm_percpu_wq] [path = ] [parameters = ] [type = operatingSystem] [pid = 10] [status = invalid] [name = gorgone-proxy] [path = gorgone-proxy] [parameters = ] [type = application] [pid = 777] [status = runnable]