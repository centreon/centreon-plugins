*** Settings ***
Documentation       network::mellanox::snmp::plugin
Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=network::mellanox::snmp::plugin
...         --mode=uptime
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-community=network/mellanox/snmp/mellanox

*** Test Cases ***
Uptime ${tc}
    [Tags]    network    mellanox    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:      tc    extra_options          expected_result    --
            ...     1    ${EMPTY}               OK: System uptime is: 289d 2m 21s | 'uptime'=24969741.00s;;;0;
            ...     2    --warning-uptime=1     WARNING: System uptime is: 289d 2m 21s | 'uptime'=24969741.00s;0:1;;0;
            ...     3    --critical-uptime=1    CRITICAL: System uptime is: 289d 2m 21s | 'uptime'=24969741.00s;;0:1;0;

