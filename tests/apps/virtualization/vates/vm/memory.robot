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
...                 --mode=memory
...                 --password=C3POR2P2
...                 --username=obi-wan
...                 --hostname=127.0.0.1
...                 --proto=http
...                 --port=3000


*** Test Cases ***
Memory ${tc}
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
    ...    OK: 26.96 % of the memory is used - 1.08GB out of 4.00GB total - total memory is 4294955008 B | 'vm.memory.usage.percentage'=26.96%;0:80;0:95;0;100 'vm.memory.usage.bytes'=1157857280B;;;0;4294955008 'vm.memory.total.bytes'=4294955008B;;;0;
    ...    3
    ...    --vm-name=XOA
    ...    OK: 26.96 % of the memory is used - 1.08GB out of 4.00GB total - total memory is 4294955008 B | 'vm.memory.usage.percentage'=26.96%;0:80;0:95;0;100 'vm.memory.usage.bytes'=1157857280B;;;0;4294955008 'vm.memory.total.bytes'=4294955008B;;;0;
    ...    4
    ...    --vm-name=XOA --warning-memory-usage-prct=1
    ...    WARNING: 26.96 % of the memory is used | 'vm.memory.usage.percentage'=26.96%;0:1;0:95;0;100 'vm.memory.usage.bytes'=1157857280B;;;0;4294955008 'vm.memory.total.bytes'=4294955008B;;;0;
    ...    5
    ...    --vm-name=XOA --critical-memory-usage-prct=1
    ...    CRITICAL: 26.96 % of the memory is used | 'vm.memory.usage.percentage'=26.96%;0:80;0:1;0;100 'vm.memory.usage.bytes'=1157857280B;;;0;4294955008 'vm.memory.total.bytes'=4294955008B;;;0;
    ...    6
    ...    --vm-name=XOA --warning-memory-usage-bytes=1
    ...    WARNING: 1.08GB out of 4.00GB total | 'vm.memory.usage.percentage'=26.96%;0:80;0:95;0;100 'vm.memory.usage.bytes'=1157857280B;0:1;;0;4294955008 'vm.memory.total.bytes'=4294955008B;;;0;
    ...    7
    ...    --vm-name=XOA --critical-memory-usage-bytes=1
    ...    CRITICAL: 1.08GB out of 4.00GB total | 'vm.memory.usage.percentage'=26.96%;0:80;0:95;0;100 'vm.memory.usage.bytes'=1157857280B;;0:1;0;4294955008 'vm.memory.total.bytes'=4294955008B;;;0;
    ...    8
    ...    --vm-name=XOA --warning-memory-total-bytes=1
    ...    WARNING: total memory is 4294955008 B | 'vm.memory.usage.percentage'=26.96%;0:80;0:95;0;100 'vm.memory.usage.bytes'=1157857280B;;;0;4294955008 'vm.memory.total.bytes'=4294955008B;0:1;;0;
    ...    9
    ...    --vm-name=XOA --critical-memory-total-bytes=1
    ...    CRITICAL: total memory is 4294955008 B | 'vm.memory.usage.percentage'=26.96%;0:80;0:95;0;100 'vm.memory.usage.bytes'=1157857280B;;;0;4294955008 'vm.memory.total.bytes'=4294955008B;;0:1;0;
