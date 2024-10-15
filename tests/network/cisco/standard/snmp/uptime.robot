*** Settings ***
Documentation       Network citrix netscaler health

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::cisco::standard::snmp::plugin


*** Test Cases ***
uptime ${tc}
    [Tags]    network    citrix    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=uptime
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/cisco/standard/snmp/cisco
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                         expected_result    --
            ...      1     --verbose                                                             OK: System uptime is: 19d 16h 25m 40s | 'uptime'=1700740.00s;;;0;
            ...      2     --check-overload                                                      OK: System uptime is: 19d 16h 25m 40s | 'uptime'=1700740.00s;;;0;
            ...      3     --reboot-window                                                       OK: System uptime is: 19d 16h 25m 40s | 'uptime'=1700740.00s;;;0;
            ...      4     --unit='s'                                                            OK: System uptime is: 19d 16h 25m 40s | 'uptime'=1700740.00s;;;0;