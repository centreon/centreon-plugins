*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json

${CMD}              ${CENTREON_PLUGINS} --plugin=apps::vmware::vsphere8::vcenter::plugin
...                 --mode=vm-count
...                 --password=C3POR2P2
...                 --username=obi-wan
...                 --hostname=127.0.0.1
...                 --proto=http
...                 --port=3000


*** Test Cases ***
Vm-Count ${tc}
    [Tags]    apps    api    vmware    vsphere8    esx
    ${command_curl}    Catenate    ${CMD} --http-backend=curl ${extraoptions}
    ${command_lwp}    Catenate    ${CMD} --http-backend=lwp ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command_curl}    ${expected_result}
    Ctn Run Command And Check Result As Strings    ${command_lwp}    ${expected_result}

    Examples:    tc     extraoptions                                    expected_result   --
        ...      1      ${EMPTY}                                        OK: 1 VM(s) powered on, 1 VM(s) powered off, 1 VM(s) suspended, 3 VM(s) in total | 'vm.poweredon.count'=1;;;0;3 'vm.poweredoff.count'=1;;;0;3 'vm.suspended.count'=1;;;0;3 'vm.total.count'=3;1:;;0;
        ...      2      --include-name=toto                             WARNING: 0 VM(s) in total | 'vm.poweredon.count'=0;;;0;0 'vm.poweredoff.count'=0;;;0;0 'vm.suspended.count'=0;;;0;0 'vm.total.count'=0;1:;;0;
        ...      3      --include-name=fav                              OK: 1 VM(s) powered on, 0 VM(s) powered off, 0 VM(s) suspended, 1 VM(s) in total | 'vm.poweredon.count'=1;;;0;1 'vm.poweredoff.count'=0;;;0;1 'vm.suspended.count'=0;;;0;1 'vm.total.count'=1;1:;;0;
        ...      4      --warning-on-count=1:                           OK: 1 VM(s) powered on, 1 VM(s) powered off, 1 VM(s) suspended, 3 VM(s) in total | 'vm.poweredon.count'=1;1:;;0;3 'vm.poweredoff.count'=1;;;0;3 'vm.suspended.count'=1;;;0;3 'vm.total.count'=3;1:;;0;
        ...      5      --critical-on-count=1:                          OK: 1 VM(s) powered on, 1 VM(s) powered off, 1 VM(s) suspended, 3 VM(s) in total | 'vm.poweredon.count'=1;;1:;0;3 'vm.poweredoff.count'=1;;;0;3 'vm.suspended.count'=1;;;0;3 'vm.total.count'=3;1:;;0;
        ...      6      --warning-on-count=2:                           WARNING: 1 VM(s) powered on | 'vm.poweredon.count'=1;2:;;0;3 'vm.poweredoff.count'=1;;;0;3 'vm.suspended.count'=1;;;0;3 'vm.total.count'=3;1:;;0;
        ...      7      --critical-on-count=2:                          CRITICAL: 1 VM(s) powered on | 'vm.poweredon.count'=1;;2:;0;3 'vm.poweredoff.count'=1;;;0;3 'vm.suspended.count'=1;;;0;3 'vm.total.count'=3;1:;;0;
        ...      8      --exclude-name=.*                               WARNING: 0 VM(s) in total | 'vm.poweredon.count'=0;;;0;0 'vm.poweredoff.count'=0;;;0;0 'vm.suspended.count'=0;;;0;0 'vm.total.count'=0;1:;;0;
        ...      9      --exclude-name=fav                              OK: 0 VM(s) powered on, 1 VM(s) powered off, 1 VM(s) suspended, 2 VM(s) in total | 'vm.poweredon.count'=0;;;0;2 'vm.poweredoff.count'=1;;;0;2 'vm.suspended.count'=1;;;0;2 'vm.total.count'=2;1:;;0;
        ...      10     --warning-off-count=1:                          OK: 1 VM(s) powered on, 1 VM(s) powered off, 1 VM(s) suspended, 3 VM(s) in total | 'vm.poweredon.count'=1;;;0;3 'vm.poweredoff.count'=1;1:;;0;3 'vm.suspended.count'=1;;;0;3 'vm.total.count'=3;1:;;0;
        ...      11     --critical-off-count=1:                         OK: 1 VM(s) powered on, 1 VM(s) powered off, 1 VM(s) suspended, 3 VM(s) in total | 'vm.poweredon.count'=1;;;0;3 'vm.poweredoff.count'=1;;1:;0;3 'vm.suspended.count'=1;;;0;3 'vm.total.count'=3;1:;;0;
        ...      12     --warning-off-count=2:                          WARNING: 1 VM(s) powered off | 'vm.poweredon.count'=1;;;0;3 'vm.poweredoff.count'=1;2:;;0;3 'vm.suspended.count'=1;;;0;3 'vm.total.count'=3;1:;;0;
        ...      13     --critical-off-count=2:                         CRITICAL: 1 VM(s) powered off | 'vm.poweredon.count'=1;;;0;3 'vm.poweredoff.count'=1;;2:;0;3 'vm.suspended.count'=1;;;0;3 'vm.total.count'=3;1:;;0;
        ...      14     --warning-total-count=4:                        WARNING: 3 VM(s) in total | 'vm.poweredon.count'=1;;;0;3 'vm.poweredoff.count'=1;;;0;3 'vm.suspended.count'=1;;;0;3 'vm.total.count'=3;4:;;0;
        ...      15     --critical-total-count=4:                       CRITICAL: 3 VM(s) in total | 'vm.poweredon.count'=1;;;0;3 'vm.poweredoff.count'=1;;;0;3 'vm.suspended.count'=1;;;0;3 'vm.total.count'=3;1:;4:;0;
        ...      16     --warning-total-count=2:                        OK: 1 VM(s) powered on, 1 VM(s) powered off, 1 VM(s) suspended, 3 VM(s) in total | 'vm.poweredon.count'=1;;;0;3 'vm.poweredoff.count'=1;;;0;3 'vm.suspended.count'=1;;;0;3 'vm.total.count'=3;2:;;0;
        ...      17     --critical-total-count=2:                       OK: 1 VM(s) powered on, 1 VM(s) powered off, 1 VM(s) suspended, 3 VM(s) in total | 'vm.poweredon.count'=1;;;0;3 'vm.poweredoff.count'=1;;;0;3 'vm.suspended.count'=1;;;0;3 'vm.total.count'=3;1:;2:;0;
        ...      18     --warning-suspended-count=1:                    OK: 1 VM(s) powered on, 1 VM(s) powered off, 1 VM(s) suspended, 3 VM(s) in total | 'vm.poweredon.count'=1;;;0;3 'vm.poweredoff.count'=1;;;0;3 'vm.suspended.count'=1;1:;;0;3 'vm.total.count'=3;1:;;0;
        ...      19     --critical-suspended-count=1:                   OK: 1 VM(s) powered on, 1 VM(s) powered off, 1 VM(s) suspended, 3 VM(s) in total | 'vm.poweredon.count'=1;;;0;3 'vm.poweredoff.count'=1;;;0;3 'vm.suspended.count'=1;;1:;0;3 'vm.total.count'=3;1:;;0;
        ...      20     --warning-suspended-count=2:                    WARNING: 1 VM(s) suspended | 'vm.poweredon.count'=1;;;0;3 'vm.poweredoff.count'=1;;;0;3 'vm.suspended.count'=1;2:;;0;3 'vm.total.count'=3;1:;;0;
        ...      21     --critical-suspended-count=2:                   CRITICAL: 1 VM(s) suspended | 'vm.poweredon.count'=1;;;0;3 'vm.poweredoff.count'=1;;;0;3 'vm.suspended.count'=1;;2:;0;3 'vm.total.count'=3;1:;;0;
        ...      22     --critical-suspended-count=2: --warning-on-count=2: --critical-total-count=4: --warning-off-count=2:                 CRITICAL: 1 VM(s) powered on, 1 VM(s) powered off, 1 VM(s) suspended, 3 VM(s) in total | 'vm.poweredon.count'=1;2:;;0;3 'vm.poweredoff.count'=1;2:;;0;3 'vm.suspended.count'=1;;2:;0;3 'vm.total.count'=3;1:;4:;0;
