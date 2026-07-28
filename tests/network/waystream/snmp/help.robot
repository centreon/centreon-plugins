*** Settings ***
Documentation       network::waystream::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::waystream::snmp::plugin


*** Test Cases ***
Help ${tc} - ${mode}
    [Tags]    network    waystream    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=${mode}
    ...    --help

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_result}

    Examples:    tc    mode    expected_result    --
    ...    1
    ...    arp
    ...    ^Plugin Description:
    ...    2
    ...    cpu
    ...    ^Plugin Description:
    ...    3
    ...    cpu-detailed
    ...    ^Plugin Description:
    ...    4
    ...    hardware
    ...    ^Plugin Description:
    ...    5
    ...    interfaces
    ...    ^Plugin Description:
    ...    6
    ...    list-interfaces
    ...    ^Plugin Description:
    ...    7
    ...    list-sfp-ports
    ...    ^Plugin Description:
    ...    8
    ...    memory
    ...    ^Plugin Description:
    ...    9
    ...    ntp
    ...    ^Plugin Description:
    ...    10
    ...    sfp-port
    ...    ^Plugin Description:
    ...    11
    ...    tcpcon
    ...    ^Plugin Description:
    ...    12
    ...    udpcon
    ...    ^Plugin Description:
    ...    13
    ...    uptime
    ...    ^Plugin Description:
