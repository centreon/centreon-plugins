*** Settings ***
Documentation       apps::virtualization::vates::vm::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::virtualization::vates::vm::plugin
...                 --mode=cpu
...                 --password=C3POR2P2
...                 --username=obi-wan
...                 --hostname=127.0.0.1
...                 --proto=http
...                 --port=3000


*** Test Cases ***
Cpu ${tc}
    [Tags]    apps    virtualization    vm
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
    ...    UNKNOWN: you must fill either --vm-uuid or --vm-name.
    ...    2
    ...    --vm-uuid=e9425768-75ed-a6da-bd00-2774c94ef200
    ...    OK: CPU usage is 35.40 % | 'vm.cpu.usage.percentage'=35.40%;;;0;100
    ...    3
    ...    --vm-name=XOA
    ...    OK: CPU usage is 35.40 % | 'vm.cpu.usage.percentage'=35.40%;;;0;100
    ...    4
    ...    --vm-name=XOA --warning-cpu-usage-prct=1
    ...    WARNING: CPU usage is 35.40 % | 'vm.cpu.usage.percentage'=35.40%;0:1;;0;100
    ...    5
    ...    --vm-name=XOA --critical-cpu-usage-prct=1
    ...    CRITICAL: CPU usage is 35.40 % | 'vm.cpu.usage.percentage'=35.40%;;0:1;0;100
