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
...                 --mode=status
...                 --password=C3POR2P2
...                 --username=obi-wan
...                 --hostname=127.0.0.1
...                 --proto=http
...                 --port=3000


*** Test Cases ***
Host Status ${tc}
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
    ...    OK: host 'vates' is Running (enabled: true), address: 192.168.122.8 [QEMU Ubuntu 24.04 PC v2 (i440FX + PIIX, arch_caps fix, 1996)]
    ...    3
    ...    --host-name=vates
    ...    OK: host 'vates' is Running (enabled: true), address: 192.168.122.8 [QEMU Ubuntu 24.04 PC v2 (i440FX + PIIX, arch_caps fix, 1996)]
    ...    4
    ...    --host-uuid=f71b4cd5-c0e5-4a94-bc96-eaefe4919104
    ...    CRITICAL: host 'vates3' is Halted (enabled: false), address: 192.168.122.81 [QEMU Ubuntu 24.04 PC (Q35 + ICH9, 2009)]
    ...    5
    ...    --host-name=vates3
    ...    CRITICAL: host 'vates3' is Halted (enabled: false), address: 192.168.122.81 [QEMU Ubuntu 24.04 PC (Q35 + ICH9, 2009)]
    ...    6
    ...    --host-name=vates3 --critical-status=${EMPTY}
    ...    OK: host 'vates3' is Halted (enabled: false), address: 192.168.122.81 [QEMU Ubuntu 24.04 PC (Q35 + ICH9, 2009)]
