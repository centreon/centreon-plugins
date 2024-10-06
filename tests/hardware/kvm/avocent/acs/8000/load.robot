*** Settings ***
Documentation       hardware::kvm::avocent::acs::8000::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${SNMPCOMMUNITY}    hardware/kvm/avocent/acs/8000/avocent8000


*** Test Cases ***
Load
    [Documentation]    load mode
    [Tags]    hardware    kvm    avocent    load    snmp
    ${output}    Run Avocent 8000 Plugin    "load"    ""

    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    OK: Load average: 0.04, 0.10, 0.15 | 'load1'=0.04;;;0; 'load5'=0.10;;;0; 'load15'=0.15;;;0;
    ...    Wrong output result for command:{\n}${output}{\n}{\n}{\n}

*** Keywords ***
Run Avocent 8000 Plugin
    [Arguments]    ${mode}    ${extraoptions}
    ${command}    Catenate
    ...    ${CENTREON_PLUGINS}
    ...    --plugin=hardware::kvm::avocent::acs::8000::snmp::plugin
    ...    --mode=${mode}
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=${SNMPCOMMUNITY}
    ...    ${extraoptions}

    ${output}    Run    ${command}
    RETURN    ${output}
