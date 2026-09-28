*** Settings ***
Documentation       network::waystream::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=network::waystream::snmp::plugin
...         --mode=udpcon
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}


*** Test Cases ***
Udpcon MS4000 ${tc}
    [Tags]    network    waystream    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --snmp-community=network/waystream/snmp/ms4000
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: Total connections: 5 | 'total#service.connections.udp.count'=5;;;0; 'connections.udp.listen.count'=5;;;0;
    ...    2
    ...    --warning=1
    ...    WARNING: Total connections: 5 | 'total#service.connections.udp.count'=5;0:1;;0; 'connections.udp.listen.count'=5;;;0;
    ...    3
    ...    --critical=1
    ...    CRITICAL: Total connections: 5 | 'total#service.connections.udp.count'=5;;0:1;0; 'connections.udp.listen.count'=5;;;0;

Udpcon MS7000 ${tc}
    [Tags]    network    waystream    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --snmp-community=network/waystream/snmp/ms7000
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: Total connections: 5 | 'total#service.connections.udp.count'=5;;;0; 'connections.udp.listen.count'=5;;;0;
    ...    2
    ...    --warning=1
    ...    WARNING: Total connections: 5 | 'total#service.connections.udp.count'=5;0:1;;0; 'connections.udp.listen.count'=5;;;0;
    ...    3
    ...    --critical=1
    ...    CRITICAL: Total connections: 5 | 'total#service.connections.udp.count'=5;;0:1;0; 'connections.udp.listen.count'=5;;;0;
