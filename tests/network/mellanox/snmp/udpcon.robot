*** Settings ***
Documentation       network::mellanox::snmp::plugin
Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=network::mellanox::snmp::plugin
...         --mode=udpcon
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-community=network/mellanox/snmp/mellanox

*** Test Cases ***
Udpcon ${tc}
    [Tags]    network    mellanox    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:      tc    extra_options      expected_result    --
            ...     1    ${EMPTY}           OK: Total connections: 18 | 'service_total'=18;;;0; 'con_listen'=18;;;0;
            ...     2    --warning=1        WARNING: Total connections: 18 | 'service_total'=18;0:1;;0; 'con_listen'=18;;;0;
            ...     3    --critical=1       CRITICAL: Total connections: 18 | 'service_total'=18;;0:1;0; 'con_listen'=18;;;0;

