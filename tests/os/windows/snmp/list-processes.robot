*** Settings ***
Documentation       Linux Local Systemd-sc-status

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}

*** Test Cases ***
list-processes ${tc}
    [Tags]    os    linux
    ${command}    Catenate
    ...    ${CMD}
    ...    --plugin=os::windows::snmp::plugin
    ...    --mode=list-processes
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/windows/snmp/windows
    ...    --snmp-timeout=1
    ...    ${extra_options}
    
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                           expected_result    --
            ...      1     --filter-name='centreontrapd'           List processes: [name = centreontrapd] [path = /usr/bin/perl] [parameters = /usr/share/centreon/bin/centreontrapd --logfile=/var/log/centreon/centreontrapd.log --severity=error --config=/etc/centreon/conf] [type = application] [pid = 589] [status = runnable]
            ...      2     --filter-name='systemd-udevd'           List processes: [name = systemd-udevd] [path = /usr/lib/systemd/systemd-udevd] [parameters = ] [type = application] [pid = 519] [status = runnable]
            ...      3     --filter-name='kdevtmpfs'               List processes: [name = kdevtmpfs] [path = ] [parameters = ] [type = operatingSystem] [pid = 26] [status = runnable]
            ...      4     --filter-name='gorgone-dbclean'         List processes: [name = gorgone-dbclean] [path = gorgone-dbcleaner] [parameters = ] [type = application] [pid = 622] [status = runnable]