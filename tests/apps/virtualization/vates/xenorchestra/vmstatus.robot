*** Settings ***
Documentation       apps::virtualization::vates::xenorchestra::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}..${/}mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::virtualization::vates::xenorchestra::plugin
...                 --mode=vm-status
...                 --password=C3POR2P2
...                 --username=obi-wan
...                 --hostname=127.0.0.1
...                 --proto=http
...                 --port=3000


*** Test Cases ***
Vm Status ${tc}
    [Tags]    apps    virtualization    xenorchestra
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
    ...    OK: 3 VM(s) running, 2 VM(s) halted, 1 VM(s) paused, 1 VM(s) suspended, 7 VM(s) total | 'vms.running.count'=3;;;0;7 'vms.halted.count'=2;;;0;7 'vms.paused.count'=1;;;0;7 'vms.suspended.count'=1;;;0;7 'vms.total.count'=7;;;0;7
    ...    2
    ...    --warning-running=2
    ...    WARNING: 3 VM(s) running | 'vms.running.count'=3;0:2;;0;7 'vms.halted.count'=2;;;0;7 'vms.paused.count'=1;;;0;7 'vms.suspended.count'=1;;;0;7 'vms.total.count'=7;;;0;7
    ...    3
    ...    --critical-running=2
    ...    CRITICAL: 3 VM(s) running | 'vms.running.count'=3;;0:2;0;7 'vms.halted.count'=2;;;0;7 'vms.paused.count'=1;;;0;7 'vms.suspended.count'=1;;;0;7 'vms.total.count'=7;;;0;7
    ...    4
    ...    --warning-halted=1
    ...    WARNING: 2 VM(s) halted | 'vms.running.count'=3;;;0;7 'vms.halted.count'=2;0:1;;0;7 'vms.paused.count'=1;;;0;7 'vms.suspended.count'=1;;;0;7 'vms.total.count'=7;;;0;7
    ...    5
    ...    --critical-halted=1
    ...    CRITICAL: 2 VM(s) halted | 'vms.running.count'=3;;;0;7 'vms.halted.count'=2;;0:1;0;7 'vms.paused.count'=1;;;0;7 'vms.suspended.count'=1;;;0;7 'vms.total.count'=7;;;0;7
    ...    6
    ...    --warning-paused=0
    ...    WARNING: 1 VM(s) paused | 'vms.running.count'=3;;;0;7 'vms.halted.count'=2;;;0;7 'vms.paused.count'=1;0:0;;0;7 'vms.suspended.count'=1;;;0;7 'vms.total.count'=7;;;0;7
    ...    7
    ...    --critical-paused=0
    ...    CRITICAL: 1 VM(s) paused | 'vms.running.count'=3;;;0;7 'vms.halted.count'=2;;;0;7 'vms.paused.count'=1;;0:0;0;7 'vms.suspended.count'=1;;;0;7 'vms.total.count'=7;;;0;7
    ...    8
    ...    --warning-suspended=0
    ...    WARNING: 1 VM(s) suspended | 'vms.running.count'=3;;;0;7 'vms.halted.count'=2;;;0;7 'vms.paused.count'=1;;;0;7 'vms.suspended.count'=1;0:0;;0;7 'vms.total.count'=7;;;0;7
    ...    9
    ...    --critical-suspended=0
    ...    CRITICAL: 1 VM(s) suspended | 'vms.running.count'=3;;;0;7 'vms.halted.count'=2;;;0;7 'vms.paused.count'=1;;;0;7 'vms.suspended.count'=1;;0:0;0;7 'vms.total.count'=7;;;0;7
    ...    10
    ...    --warning-total=5
    ...    WARNING: 7 VM(s) total | 'vms.running.count'=3;;;0;7 'vms.halted.count'=2;;;0;7 'vms.paused.count'=1;;;0;7 'vms.suspended.count'=1;;;0;7 'vms.total.count'=7;0:5;;0;7
    ...    11
    ...    --critical-total=5
    ...    CRITICAL: 7 VM(s) total | 'vms.running.count'=3;;;0;7 'vms.halted.count'=2;;;0;7 'vms.paused.count'=1;;;0;7 'vms.suspended.count'=1;;;0;7 'vms.total.count'=7;;0:5;0;7
    ...    12
    ...    --include-vm-name=run
    ...    OK: 3 VM(s) running, 0 VM(s) halted, 0 VM(s) paused, 0 VM(s) suspended, 3 VM(s) total | 'vms.running.count'=3;;;0;3 'vms.halted.count'=0;;;0;3 'vms.paused.count'=0;;;0;3 'vms.suspended.count'=0;;;0;3 'vms.total.count'=3;;;0;3
    ...    13
    ...    --exclude-vm-name=run
    ...    OK: 0 VM(s) running, 2 VM(s) halted, 1 VM(s) paused, 1 VM(s) suspended, 4 VM(s) total | 'vms.running.count'=0;;;0;4 'vms.halted.count'=2;;;0;4 'vms.paused.count'=1;;;0;4 'vms.suspended.count'=1;;;0;4 'vms.total.count'=4;;;0;4
    ...    14
    ...    --include-vm-name=does-not-exist
    ...    UNKNOWN: no vm found, check include and exclude filters.
