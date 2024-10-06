*** Settings ***
Documentation       hardware::kvm::avocent::acs::8000::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${SNMPCOMMUNITY}    hardware/kvm/avocent/acs/8000/avocent8000


*** Test Cases ***
Hardware
    [Documentation]    hardware mode
    [Tags]    hardware    kvm    avocent    hardware-mode    snmp
    ${output}    Run Avocent 8000 Plugin    "hardware"    ""

    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    OK: All 2 components are ok [2/2 psus]. | 'hardware.psu.count'=2;;;;
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
