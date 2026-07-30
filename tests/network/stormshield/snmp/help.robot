*** Settings ***
Documentation       network::stormshield::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::stormshield::snmp::plugin


*** Test Cases ***
Standard ${tc} - ${mode}
    [Tags]    network    stormshield    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=${mode}
    ...    --help

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_result}    flags=IGNORECASE

    Examples:
    ...    tc
    ...    mode
    ...    expected_result
    ...    --
    ...    1
    ...    connections
    ...    Mode:\n.*connections
    ...    2
    ...    cpu
    ...    Mode:\n.*cpu
    ...    3
    ...    cpu-detailed
    ...    Mode:\n.*Check system CPUs
    ...    4
    ...    ha-nodes
    ...    Mode:\n.*Check Stormshield nodes status
    ...    5
    ...    hardware
    ...    Mode:\n.*hardware
    ...    6
    ...    health
    ...    Mode:\n.*health
    ...    7
    ...    interfaces
    ...    Mode:\n.*interfaces
    ...    8
    ...    list-interfaces
    ...    Mode:\n.*--interface
    ...    9
    ...    load
    ...    Mode:\n.*load
    ...    10
    ...    memory
    ...    Mode:\n.*memory
    ...    11
    ...    memory-detailed
    ...    Mode:\n.*memory
    ...    12
    ...    qos
    ...    Mode:\n.*qos
    ...    13
    ...    storage
    ...    Mode:\n.*--warning-usage
    ...    14
    ...    swap
    ...    Mode:\n.*swap
    ...    15
    ...    uptime
    ...    Mode:\n.*uptime
    ...    16
    ...    vpn-status
    ...    Mode:\n.*Check vpn
    ...    17
    ...    licenses
    ...    Mode:\n.*licenses
    ...    18
    ...    auto-update
    ...    Mode:\n.*auto.update
