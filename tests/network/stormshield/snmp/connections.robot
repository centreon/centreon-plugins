*** Settings ***
Documentation       network::stormshield::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=network::stormshield::snmp::plugin
...         --mode=connections
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-version=${SNMPVERSION}


*** Test Cases ***
Connections SN910 ${tc}
    [Tags]    network    stormshield    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --snmp-community=network/stormshield/snmp/sn910
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: UDP : 318 connections, TCP : 0 connections, Major Alarms : 0, Minor Alarms : 0 | 'connections.udp.count'=318;;;0; 'connections.tcp.count'=0;;;0; 'alarms.major.count'=0;;;0; 'alarms.minor.count'=0;;;0;
    ...    2
    ...    --warning-tcp=1:
    ...    WARNING: TCP : 0 connections | 'connections.udp.count'=318;;;0; 'connections.tcp.count'=0;1:;;0; 'alarms.major.count'=0;;;0; 'alarms.minor.count'=0;;;0;
    ...    3
    ...    --warning-udp=1
    ...    WARNING: UDP : 318 connections | 'connections.udp.count'=318;0:1;;0; 'connections.tcp.count'=0;;;0; 'alarms.major.count'=0;;;0; 'alarms.minor.count'=0;;;0;
    ...    4
    ...    --warning-major=1:
    ...    WARNING: Major Alarms : 0 | 'connections.udp.count'=318;;;0; 'connections.tcp.count'=0;;;0; 'alarms.major.count'=0;1:;;0; 'alarms.minor.count'=0;;;0;
    ...    5
    ...    --warning-minor=1:
    ...    WARNING: Minor Alarms : 0 | 'connections.udp.count'=318;;;0; 'connections.tcp.count'=0;;;0; 'alarms.major.count'=0;;;0; 'alarms.minor.count'=0;1:;;0;
    ...    6
    ...    --critical-tcp=1:
    ...    CRITICAL: TCP : 0 connections | 'connections.udp.count'=318;;;0; 'connections.tcp.count'=0;;1:;0; 'alarms.major.count'=0;;;0; 'alarms.minor.count'=0;;;0;
    ...    7
    ...    --critical-udp=1
    ...    CRITICAL: UDP : 318 connections | 'connections.udp.count'=318;;0:1;0; 'connections.tcp.count'=0;;;0; 'alarms.major.count'=0;;;0; 'alarms.minor.count'=0;;;0;
    ...    8
    ...    --critical-major=1:
    ...    CRITICAL: Major Alarms : 0 | 'connections.udp.count'=318;;;0; 'connections.tcp.count'=0;;;0; 'alarms.major.count'=0;;1:;0; 'alarms.minor.count'=0;;;0;
    ...    9
    ...    --critical-minor=1:
    ...    CRITICAL: Minor Alarms : 0 | 'connections.udp.count'=318;;;0; 'connections.tcp.count'=0;;;0; 'alarms.major.count'=0;;;0; 'alarms.minor.count'=0;;1:;0;
