*** Settings ***
Documentation       cloud::zscaler::ztb::restapi::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=cloud::zscaler::ztb::restapi::plugin


*** Test Cases ***
Standard ${tc} - ${mode}
    [Tags]    cloud    zscaler    restapi
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
    ...    cache
    ...    Mode:\n.*cache
    ...    2
    ...    cluster-appconnector
    ...    Mode:\n.*App Connector
    ...    3
    ...    cluster-ipsec
    ...    Mode:\n.*clusters IPsec
    ...    4
    ...    discovery
    ...    Mode:\n.*discovery
    ...    5
    ...    gateway-containers
    ...    Mode:\n.*gateway.containers
    ...    6
    ...    gateway-cpu
    ...    Mode:\n.*gateway.cpu
    ...    7
    ...    gateway-disk
    ...    Mode:\n.*gateway.disk
    ...    8
    ...    gateway-interfaces
    ...    Mode:\n.*gateway.interfaces
    ...    9
    ...    gateway-memory
    ...    Mode:\n.*gateway.memory
    ...    10
    ...    gateway-status
    ...    Mode:\n.*gateway.status
