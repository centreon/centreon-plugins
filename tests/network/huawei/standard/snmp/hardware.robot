*** Settings ***
Documentation       network::huawei::standard::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=network::huawei::standard::snmp::plugin
...         --mode=hardware --component=fan
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-community=network/huawei/standard/snmp/huawei_fan


*** Test Cases ***
Gpon-ont-health ${tc}
    [Tags]    network    huawei    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: All 12 components are ok [3/12 fans]. | '1.7#hardware.fan.speed.percentage'=30%;;;0; '2.7#hardware.fan.speed.percentage'=30%;;;0; '3.7#hardware.fan.speed.percentage'=30%;;;0; 'hardware.fan.count'=3;;;;
    ...    2
    ...    --absent-problem=fan,1.8
    ...    CRITICAL: Component 'fan' instance '1.8' is not present | '1.7#hardware.fan.speed.percentage'=30%;;;0; '2.7#hardware.fan.speed.percentage'=30%;;;0; '3.7#hardware.fan.speed.percentage'=30%;;;0; 'hardware.fan.count'=3;;;;
    ...    3
    ...    --component=temperature
    ...    CRITICAL: Component 'fan' instance '1.8' is not present | '1.7#hardware.fan.speed.percentage'=30%;;;0; '2.7#hardware.fan.speed.percentage'=30%;;;0; '3.7#hardware.fan.speed.percentage'=30%;;;0; 'hardware.fan.count'=3;;;;
    ...    4
    ...    --component=temperature --no-component=OK
    ...    OK: All 0 components are ok []. - No components are checked.
