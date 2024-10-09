*** Settings ***
Documentation       cpu-detailed mode

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${SNMPCOMMUNITY}    hardware/kvm/avocent/acs/8000/avocent8000


*** Test Cases ***
Cpu-Detailed
    [Tags]    hardware    kvm    avocent    cpu    snmp
    Remove File    /dev/shm/snmpstandard_127.0.0.1_2024_cpu-detailed*
    ${output}    Run Avocent 8000 Plugin    "cpu-detailed"    --statefile-dir=/dev/shm/
    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    OK: CPU Usage: user : Buffer creation, nice : Buffer creation, system : Buffer creation, idle : Buffer creation, wait : Buffer creation, kernel : Buffer creation, interrupt : Buffer creation, softirq : Buffer creation, steal : Buffer creation, guest : Buffer creation, guestnice : Buffer creation
    ...    Wrong output result for command:{\n}${output}{\n}{\n}{\n}

    ${output}    Run Avocent 8000 Plugin    "cpu-detailed"    --statefile-dir=/dev/shm/
    ${output}    Strip String    ${output}
    Remove File    /dev/shm/snmpstandard_127.0.0.1_2024_cpu-detailed*
    Should Be Equal As Strings
    ...    ${output}
    ...    OK: CPU Usage: user : counter not moved, nice : counter not moved, system : counter not moved, idle : counter not moved, wait : counter not moved, kernel : counter not moved, interrupt : counter not moved, softirq : counter not moved, steal : counter not moved, guest : counter not moved, guestnice : counter not moved
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
