*** Settings ***
Documentation       HPE Primera Storage

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
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
        ...      1        ${EMPTY}                       CRITICAL: Disk WDC-WLEB14T0S5xeF7.2-9MJ4SWLT (position 7:5:0) is failed WARNING: Disk WDC-WLEB14T0S5xeF7.2-9MJ4N1TT (position 8:5:0) is new - Disk WDC-WLEB14T0S5xeF7.2-9MJ4N8UT (position 8:7:0) is degraded - Disk WDC-WLEB14T0S5xeF7.2-9MJ4SSKT (position 8:1:0) is unknown - Disk WDC-WLEB14T0S5xeF7.2-9MJ4TLLT (position 8:4:0) is new | 'disks.total.count'=82;;;0; 'disks.normal.count'=77;;;0;82 'disks.degraded.count'=1;;;0;82 'disks.new.count'=2;;;0;82 'disks.failed.count'=1;;;0;82 'disks.unknown.count'=1;;;0;82
        ...      2        --critical-status=''           WARNING: Disk WDC-WLEB14T0S5xeF7.2-9MJ4N1TT (position 8:5:0) is new - Disk WDC-WLEB14T0S5xeF7.2-9MJ4N8UT (position 8:7:0) is degraded - Disk WDC-WLEB14T0S5xeF7.2-9MJ4SSKT (position 8:1:0) is unknown - Disk WDC-WLEB14T0S5xeF7.2-9MJ4TLLT (position 8:4:0) is new | 'disks.total.count'=82;;;0; 'disks.normal.count'=77;;;0;82 'disks.degraded.count'=1;;;0;82 'disks.new.count'=2;;;0;82 'disks.failed.count'=1;;;0;82 'disks.unknown.count'=1;;;0;82
        ...      3        --warning-status=''            CRITICAL: Disk WDC-WLEB14T0S5xeF7.2-9MJ4SWLT (position 7:5:0) is failed | 'disks.total.count'=82;;;0; 'disks.normal.count'=77;;;0;82 'disks.degraded.count'=1;;;0;82 'disks.new.count'=2;;;0;82 'disks.failed.count'=1;;;0;82 'disks.unknown.count'=1;;;0;82
        ...      4        --warning-disks-new=0          CRITICAL: Disk WDC-WLEB14T0S5xeF7.2-9MJ4SWLT (position 7:5:0) is failed WARNING: Disks new: 2 - Disk WDC-WLEB14T0S5xeF7.2-9MJ4N1TT (position 8:5:0) is new - Disk WDC-WLEB14T0S5xeF7.2-9MJ4N8UT (position 8:7:0) is degraded - Disk WDC-WLEB14T0S5xeF7.2-9MJ4SSKT (position 8:1:0) is unknown - Disk WDC-WLEB14T0S5xeF7.2-9MJ4TLLT (position 8:4:0) is new | 'disks.total.count'=82;;;0; 'disks.normal.count'=77;;;0;82 'disks.degraded.count'=1;;;0;82 'disks.new.count'=2;0:0;;0;82 'disks.failed.count'=1;;;0;82 'disks.unknown.count'=1;;;0;82
        ...      5        --warning-disks-total=83:83    CRITICAL: Disk WDC-WLEB14T0S5xeF7.2-9MJ4SWLT (position 7:5:0) is failed WARNING: Disks total: 82 - Disk WDC-WLEB14T0S5xeF7.2-9MJ4N1TT (position 8:5:0) is new - Disk WDC-WLEB14T0S5xeF7.2-9MJ4N8UT (position 8:7:0) is degraded - Disk WDC-WLEB14T0S5xeF7.2-9MJ4SSKT (position 8:1:0) is unknown - Disk WDC-WLEB14T0S5xeF7.2-9MJ4TLLT (position 8:4:0) is new | 'disks.total.count'=82;83:83;;0; 'disks.normal.count'=77;;;0;82 'disks.degraded.count'=1;;;0;82 'disks.new.count'=2;;;0;82 'disks.failed.count'=1;;;0;82 'disks.unknown.count'=1;;;0;82
        ...      6        --critical-disks-failed=0      CRITICAL: Disks failed: 1 - Disk WDC-WLEB14T0S5xeF7.2-9MJ4SWLT (position 7:5:0) is failed WARNING: Disk WDC-WLEB14T0S5xeF7.2-9MJ4N1TT (position 8:5:0) is new - Disk WDC-WLEB14T0S5xeF7.2-9MJ4N8UT (position 8:7:0) is degraded - Disk WDC-WLEB14T0S5xeF7.2-9MJ4SSKT (position 8:1:0) is unknown - Disk WDC-WLEB14T0S5xeF7.2-9MJ4TLLT (position 8:4:0) is new | 'disks.total.count'=82;;;0; 'disks.normal.count'=77;;;0;82 'disks.degraded.count'=1;;;0;82 'disks.new.count'=2;;;0;82 'disks.failed.count'=1;;0:0;0;82 'disks.unknown.count'=1;;;0;82
        ...      7        --warning-disks-degraded=0     CRITICAL: Disk WDC-WLEB14T0S5xeF7.2-9MJ4SWLT (position 7:5:0) is failed WARNING: Disks degraded: 1 - Disk WDC-WLEB14T0S5xeF7.2-9MJ4N1TT (position 8:5:0) is new - Disk WDC-WLEB14T0S5xeF7.2-9MJ4N8UT (position 8:7:0) is degraded - Disk WDC-WLEB14T0S5xeF7.2-9MJ4SSKT (position 8:1:0) is unknown - Disk WDC-WLEB14T0S5xeF7.2-9MJ4TLLT (position 8:4:0) is new | 'disks.total.count'=82;;;0; 'disks.normal.count'=77;;;0;82 'disks.degraded.count'=1;0:0;;0;82 'disks.new.count'=2;;;0;82 'disks.failed.count'=1;;;0;82 'disks.unknown.count'=1;;;0;82
        ...      8        --warning-disks-unknown=0      CRITICAL: Disk WDC-WLEB14T0S5xeF7.2-9MJ4SWLT (position 7:5:0) is failed WARNING: Disks unknown: 1 - Disk WDC-WLEB14T0S5xeF7.2-9MJ4N1TT (position 8:5:0) is new - Disk WDC-WLEB14T0S5xeF7.2-9MJ4N8UT (position 8:7:0) is degraded - Disk WDC-WLEB14T0S5xeF7.2-9MJ4SSKT (position 8:1:0) is unknown - Disk WDC-WLEB14T0S5xeF7.2-9MJ4TLLT (position 8:4:0) is new | 'disks.total.count'=82;;;0; 'disks.normal.count'=77;;;0;82 'disks.degraded.count'=1;;;0;82 'disks.new.count'=2;;;0;82 'disks.failed.count'=1;;;0;82 'disks.unknown.count'=1;0:0;;0;82
        ...      9        --warning-disks-normal=82:82   CRITICAL: Disk WDC-WLEB14T0S5xeF7.2-9MJ4SWLT (position 7:5:0) is failed WARNING: Disks normal: 77 - Disk WDC-WLEB14T0S5xeF7.2-9MJ4N1TT (position 8:5:0) is new - Disk WDC-WLEB14T0S5xeF7.2-9MJ4N8UT (position 8:7:0) is degraded - Disk WDC-WLEB14T0S5xeF7.2-9MJ4SSKT (position 8:1:0) is unknown - Disk WDC-WLEB14T0S5xeF7.2-9MJ4TLLT (position 8:4:0) is new | 'disks.total.count'=82;;;0; 'disks.normal.count'=77;82:82;;0;82 'disks.degraded.count'=1;;;0;82 'disks.new.count'=2;;;0;82 'disks.failed.count'=1;;;0;82 'disks.unknown.count'=1;;;0;82

