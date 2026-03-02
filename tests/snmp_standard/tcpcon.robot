*** Settings ***
Documentation       snmp_standard
Resource            ${CURDIR}${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --mode=tcpcon
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}

*** Test Cases ***
Mellanox-Tcpcon ${tc}
    [Tags]    network    mellanox    snmp    snmp_standard
    ${command}    Catenate
    ...    ${CMD}
    ...    --plugin=network::mellanox::snmp::plugin
    ...    --snmp-community=snmp_standard/network-mellanox
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:      tc    extra_options      expected_result    --
            ...     1    ${EMPTY}           OK: Total connections: 6 | 'service_total'=6;;;0; 'con_closeWait'=0;;;0; 'con_closed'=0;;;0; 'con_closing'=0;;;0; 'con_established'=6;;;0; 'con_finWait1'=0;;;0; 'con_finWait2'=0;;;0; 'con_lastAck'=0;;;0; 'con_listen'=7;;;0; 'con_synReceived'=0;;;0; 'con_synSent'=0;;;0; 'con_timeWait'=0;;;0;
            ...     2    --warning=1        WARNING: Total connections: 6 | 'service_total'=6;0:1;;0; 'con_closeWait'=0;;;0; 'con_closed'=0;;;0; 'con_closing'=0;;;0; 'con_established'=6;;;0; 'con_finWait1'=0;;;0; 'con_finWait2'=0;;;0; 'con_lastAck'=0;;;0; 'con_listen'=7;;;0; 'con_synReceived'=0;;;0; 'con_synSent'=0;;;0; 'con_timeWait'=0;;;0;
            ...     3    --critical=1       CRITICAL: Total connections: 6 | 'service_total'=6;;0:1;0; 'con_closeWait'=0;;;0; 'con_closed'=0;;;0; 'con_closing'=0;;;0; 'con_established'=6;;;0; 'con_finWait1'=0;;;0; 'con_finWait2'=0;;;0; 'con_lastAck'=0;;;0; 'con_listen'=7;;;0; 'con_synReceived'=0;;;0; 'con_synSent'=0;;;0; 'con_timeWait'=0;;;0;
