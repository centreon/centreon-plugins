*** Settings ***
Documentation       apps::virtualization::vates::host::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}..${/}mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::virtualization::vates::host::plugin
...                 --mode=memory
...                 --password=C3POR2P2
...                 --username=obi-wan
...                 --hostname=127.0.0.1
...                 --proto=http
...                 --port=3000


*** Test Cases ***
Host Memory ${tc}
    [Tags]    apps    virtualization    xenorchestra    host
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
    ...    UNKNOWN: you must fill either --host-uuid or --host-name.
    ...    2
    ...    --host-uuid=806ca3d4-a50f-43e7-b19a-9228b999028c
    ...    OK: 72.22 % of the memory is used - 5.78GB out of 8.00GB total - free memory is 2386386944 B | 'host.memory.usage.percentage'=72.22%;0:80;0:95;0;100 'host.memory.usage.bytes'=6203547648B;;;0;8589934592 'host.memory.free.bytes'=2386386944B;;;0;
    ...    3
    ...    --host-name=vates
    ...    OK: 72.22 % of the memory is used - 5.78GB out of 8.00GB total - free memory is 2386386944 B | 'host.memory.usage.percentage'=72.22%;0:80;0:95;0;100 'host.memory.usage.bytes'=6203547648B;;;0;8589934592 'host.memory.free.bytes'=2386386944B;;;0;
    ...    4
    ...    --host-name=vates3
    ...    OK: 0.00 % of the memory is used - 0.00B out of 4.00GB total - free memory is 4294967296 B | 'host.memory.usage.percentage'=0.00%;0:80;0:95;0;100 'host.memory.usage.bytes'=0B;;;0;4294967296 'host.memory.free.bytes'=4294967296B;;;0;
