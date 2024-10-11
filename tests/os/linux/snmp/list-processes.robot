*** Settings ***
Documentation       Check list-processes table

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

    Examples:        tc    extra_options                       expected_result    -- 
            ...      2     --filter-name='centreontrapd'       List processes: [name = centreontrapd] [path = /usr/bin/perl] [parameters = /usr/share/centreon/bin/centreontrapd --logfile=/var/log/centreon/centreontrapd.log --severity=error --config=/etc/centreon/conf] [type = application] [pid = 317] [status = runnable]
            ...      3     --filter-name='systemd-udevd'       List processes: [name = systemd-udevd] [path = /lib/systemd/systemd-udevd] [parameters = ] [type = application] [pid = 235] [status = runnable]
            ...      4     --filter-name='kdevtmpfs'           List processes: [name = kdevtmpfs] [path = ] [parameters = ] [type = operatingSystem] [pid = 26] [status = runnable]
            ...      5     --filter-name='gorgone-dbclean'     List processes: [name = gorgone-dbclean] [path = gorgone-dbcleaner] [parameters = ] [type = application] [pid = 760] [status = runnable]