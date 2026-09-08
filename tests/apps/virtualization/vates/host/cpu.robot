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
...                 --mode=cpu
...                 --password=C3POR2P2
...                 --username=obi-wan
...                 --hostname=127.0.0.1
...                 --proto=http
...                 --port=3000


*** Test Cases ***
Host Cpu ${tc}
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
    ...    OK: CPU usage is 60.00 %, 4 pCPU(s) | 'host.cpu.usage.percentage'=60.00%;0:80;0:95;0;100 'host.cpu.count'=4;;;0;
    ...    3
    ...    --host-name=vates
    ...    OK: CPU usage is 60.00 %, 4 pCPU(s) | 'host.cpu.usage.percentage'=60.00%;0:80;0:95;0;100 'host.cpu.count'=4;;;0;
    ...    4
    ...    --host-name=vates --warning-cpu-usage-prct=1
    ...    WARNING: CPU usage is 60.00 % | 'host.cpu.usage.percentage'=60.00%;0:1;0:95;0;100 'host.cpu.count'=4;;;0;
    ...    5
    ...    --host-name=vates --critical-cpu-usage-prct=1
    ...    CRITICAL: CPU usage is 60.00 % | 'host.cpu.usage.percentage'=60.00%;0:80;0:1;0;100 'host.cpu.count'=4;;;0;
    ...    6
    ...    --host-name=vates3
    ...    UNKNOWN: host 'vates3' is not enabled/running, can not get CPU usage data (HOST_OFFLINE(OpaqueRef:2f22ba81-242d-b7e2-9e6b-95b98d931af3)).
