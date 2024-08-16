*** Settings ***
Documentation       HPE Primera Storage REST API

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}hpe-primera.mockoon.json
${HOSTNAME}             127.0.0.1
${APIPORT}              3000
${CMD}              ${CENTREON_PLUGINS} 
...                 --plugin=storage::hp::primera::restapi::plugin
...                 --mode disk-status
...                 --hostname=${HOSTNAME}
...                 --api-username=toto
...                 --api-password=toto
...                 --proto=http
...                 --port=${APIPORT}
...                 --custommode=api
...                 --statefile-dir=/dev/shm/

*** Test Cases ***
Diskstatus ${tc}
    [Tags]    storage     api    hpe    hp
    ${output}    Run    ${CMD} ${extraoptions}

    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    ${expected_result}
    ...    Wrong output result for command:\n${CMD} ${extraoptions}\n\nObtained:\n${output}\n\nExpected:\n${expected_result}\n
    ...    values=False
    ...    collapse_spaces=True


    Examples:    tc        extraoptions                  expected_result   --
        ...      1        ${EMPTY}                       CRITICAL: Disk #73 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4SWLT) located 7:5:0 is failed WARNING: Disk #75 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4SSKT) located 8:1:0 is unknown - Disk #78 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4TLLT) located 8:4:0 is new - Disk #79 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4N1TT) located 8:5:0 is new - Disk #81 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4N8UT) located 8:7:0 is degraded | 'disks.total.count'=82;;;0; 'disks.normal.count'=77;;;0;82 'disks.degraded.count'=1;;;0;82 'disks.new.count'=2;;;0;82 'disks.failed.count'=1;;;0;82 'disks.unknown.count'=1;;;0;82
        ...      2        --critical-status=''           WARNING: Disk #75 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4SSKT) located 8:1:0 is unknown - Disk #78 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4TLLT) located 8:4:0 is new - Disk #79 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4N1TT) located 8:5:0 is new - Disk #81 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4N8UT) located 8:7:0 is degraded | 'disks.total.count'=82;;;0; 'disks.normal.count'=77;;;0;82 'disks.degraded.count'=1;;;0;82 'disks.new.count'=2;;;0;82 'disks.failed.count'=1;;;0;82 'disks.unknown.count'=1;;;0;82
        ...      3        --warning-status=''            CRITICAL: Disk #73 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4SWLT) located 7:5:0 is failed | 'disks.total.count'=82;;;0; 'disks.normal.count'=77;;;0;82 'disks.degraded.count'=1;;;0;82 'disks.new.count'=2;;;0;82 'disks.failed.count'=1;;;0;82 'disks.unknown.count'=1;;;0;82
        ...      4        --warning-disks-new=0          CRITICAL: Disk #73 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4SWLT) located 7:5:0 is failed WARNING: Disks new: 2 - Disk #75 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4SSKT) located 8:1:0 is unknown - Disk #78 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4TLLT) located 8:4:0 is new - Disk #79 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4N1TT) located 8:5:0 is new - Disk #81 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4N8UT) located 8:7:0 is degraded | 'disks.total.count'=82;;;0; 'disks.normal.count'=77;;;0;82 'disks.degraded.count'=1;;;0;82 'disks.new.count'=2;0:0;;0;82 'disks.failed.count'=1;;;0;82 'disks.unknown.count'=1;;;0;82
        ...      5        --warning-disks-total=83:83    CRITICAL: Disk #73 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4SWLT) located 7:5:0 is failed WARNING: Disks total: 82 - Disk #75 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4SSKT) located 8:1:0 is unknown - Disk #78 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4TLLT) located 8:4:0 is new - Disk #79 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4N1TT) located 8:5:0 is new - Disk #81 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4N8UT) located 8:7:0 is degraded | 'disks.total.count'=82;83:83;;0; 'disks.normal.count'=77;;;0;82 'disks.degraded.count'=1;;;0;82 'disks.new.count'=2;;;0;82 'disks.failed.count'=1;;;0;82 'disks.unknown.count'=1;;;0;82
        ...      6        --critical-disks-failed=0      CRITICAL: Disks failed: 1 - Disk #73 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4SWLT) located 7:5:0 is failed WARNING: Disk #75 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4SSKT) located 8:1:0 is unknown - Disk #78 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4TLLT) located 8:4:0 is new - Disk #79 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4N1TT) located 8:5:0 is new - Disk #81 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4N8UT) located 8:7:0 is degraded | 'disks.total.count'=82;;;0; 'disks.normal.count'=77;;;0;82 'disks.degraded.count'=1;;;0;82 'disks.new.count'=2;;;0;82 'disks.failed.count'=1;;0:0;0;82 'disks.unknown.count'=1;;;0;82
        ...      7        --warning-disks-degraded=0     CRITICAL: Disk #73 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4SWLT) located 7:5:0 is failed WARNING: Disks degraded: 1 - Disk #75 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4SSKT) located 8:1:0 is unknown - Disk #78 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4TLLT) located 8:4:0 is new - Disk #79 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4N1TT) located 8:5:0 is new - Disk #81 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4N8UT) located 8:7:0 is degraded | 'disks.total.count'=82;;;0; 'disks.normal.count'=77;;;0;82 'disks.degraded.count'=1;0:0;;0;82 'disks.new.count'=2;;;0;82 'disks.failed.count'=1;;;0;82 'disks.unknown.count'=1;;;0;82
        ...      8        --warning-disks-unknown=0      CRITICAL: Disk #73 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4SWLT) located 7:5:0 is failed WARNING: Disks unknown: 1 - Disk #75 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4SSKT) located 8:1:0 is unknown - Disk #78 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4TLLT) located 8:4:0 is new - Disk #79 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4N1TT) located 8:5:0 is new - Disk #81 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4N8UT) located 8:7:0 is degraded | 'disks.total.count'=82;;;0; 'disks.normal.count'=77;;;0;82 'disks.degraded.count'=1;;;0;82 'disks.new.count'=2;;;0;82 'disks.failed.count'=1;;;0;82 'disks.unknown.count'=1;0:0;;0;82
        ...      9        --warning-disks-normal=82:82   CRITICAL: Disk #73 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4SWLT) located 7:5:0 is failed WARNING: Disks normal: 77 - Disk #75 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4SSKT) located 8:1:0 is unknown - Disk #78 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4TLLT) located 8:4:0 is new - Disk #79 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4N1TT) located 8:5:0 is new - Disk #81 (WDC/WLEB14T0S5xeF7.2, serial: 9MJ4N8UT) located 8:7:0 is degraded | 'disks.total.count'=82;;;0; 'disks.normal.count'=77;82:82;;0;82 'disks.degraded.count'=1;;;0;82 'disks.new.count'=2;;;0;82 'disks.failed.count'=1;;;0;82 'disks.unknown.count'=1;;;0;82
