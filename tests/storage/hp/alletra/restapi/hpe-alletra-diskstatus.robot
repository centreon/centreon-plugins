*** Settings ***
Documentation       HPE Alletra Storage REST API Mode Disk Status

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}hpe-alletra.mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS} 
...                 --plugin=storage::hp::alletra::restapi::plugin
...                 --mode disk-status
...                 --hostname=${HOSTNAME}
...                 --api-username=xx
...                 --api-password=xx
...                 --proto=http
...                 --port=${APIPORT}

*** Test Cases ***
DiskStatus ${tc}
    [Tags]    storage     api    hpe    hp
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_regexp}


    Examples:        tc       extraoptions                                                              expected_regexp    --
            ...      1        ${EMPTY}                                                                  CRITICAL: Disk #1 (XXXX/XXXX, serial: XXXX) located 1:2 is failed WARNING: Disk #2 (XXX/XXX, serial: XXX) located 1:3 is degraded | 'disks.total.count'=3;;;0; 'disks.normal.count'=1;;;0;3 'disks.degraded.count'=1;;;0;3 'disks.new.count'=0;;;0;3 'disks.failed.count'=1;;;0;3 'disks.unknown.count'=0;;;0;3
            ...      2        --filter-id='^0$'                                                         OK: Disks total: 1, normal: 1, degraded: 0, new: 0, failed: 0, unknown: 0 - Disk #0 (XXXX1/XXXXXX1, serial: XXXXX1) located 1:1 is normal | 'disks.total.count'=1;;;0; 'disks.normal.count'=1;;;0;1 'disks.degraded.count'=0;;;0;1 'disks.new.count'=0;;;0;1 'disks.failed.count'=0;;;0;1 'disks.unknown.count'=0;;;0;1
            ...      3        --filter-manufacturer='X1$'                                               OK: Disks total: 1, normal: 1, degraded: 0, new: 0, failed: 0, unknown: 0 - Disk #0 (XXXX1/XXXXXX1, serial: XXXXX1) located 1:1 is normal | 'disks.total.count'=1;;;0; 'disks.normal.count'=1;;;0;1 'disks.degraded.count'=0;;;0;1 'disks.new.count'=0;;;0;1 'disks.failed.count'=0;;;0;1 'disks.unknown.count'=0;;;0;1
            ...      4        --filter-model='X1$'                                                      OK: Disks total: 1, normal: 1, degraded: 0, new: 0, failed: 0, unknown: 0 - Disk #0 (XXXX1/XXXXXX1, serial: XXXXX1) located 1:1 is normal | 'disks.total.count'=1;;;0; 'disks.normal.count'=1;;;0;1 'disks.degraded.count'=0;;;0;1 'disks.new.count'=0;;;0;1 'disks.failed.count'=0;;;0;1 'disks.unknown.count'=0;;;0;1
            ...      5        --filter-serial='X2$'                                                     CRITICAL: Disk #1 (XXXX2/XXXX2, serial: XXXX2) located 1:2 is failed | 'disks.total.count'=1;;;0; 'disks.normal.count'=0;;;0;1 'disks.degraded.count'=0;;;0;1 'disks.new.count'=0;;;0;1 'disks.failed.count'=1;;;0;1 'disks.unknown.count'=0;;;0;1
            ...      6        --filter-position=1:3                                                     WARNING: Disk #2 (XXX3/XXX3, serial: XXX3) located 1:3 is degraded | 'disks.total.count'=1;;;0; 'disks.normal.count'=0;;;0;1 'disks.degraded.count'=1;;;0;1 'disks.new.count'=0;;;0;1 'disks.failed.count'=0;;;0;1 'disks.unknown.count'=0;;;0;1
            ...      7        --warning-disks-new=1: --critical-status='' --warning-status=''           WARNING: Disks new: 0 | 'disks.total.count'=3;;;0; 'disks.normal.count'=1;;;0;3 'disks.degraded.count'=1;;;0;3 'disks.new.count'=0;1:;;0;3 'disks.failed.count'=1;;;0;3 'disks.unknown.count'=0;;;0;3
            ...      8        --warning-disks-degraded=:0 --critical-status='' --warning-status=''      WARNING: Disks degraded: 1 | 'disks.total.count'=3;;;0; 'disks.normal.count'=1;;;0;3 'disks.degraded.count'=1;0:0;;0;3 'disks.new.count'=0;;;0;3 'disks.failed.count'=1;;;0;3 'disks.unknown.count'=0;;;0;3
            ...      9        --critical-status='' --warning-status='' --warning-disks-new=@0:0         WARNING: Disks new: 0 | 'disks.total.count'=3;;;0; 'disks.normal.count'=1;;;0;3 'disks.degraded.count'=1;;;0;3 'disks.new.count'=0;@0:0;;0;3 'disks.failed.count'=1;;;0;3 'disks.unknown.count'=0;;;0;3
            ...      10       --critical-status='' --warning-status='' --critical-disks-failed=:0       CRITICAL: Disks failed: 1 | 'disks.total.count'=3;;;0; 'disks.normal.count'=1;;;0;3 'disks.degraded.count'=1;;;0;3 'disks.new.count'=0;;;0;3 'disks.failed.count'=1;;0:0;0;3 'disks.unknown.count'=0;;;0;3
            ...      11       --critical-status='' --warning-status='' --critical-disks-unknown=@0:0    CRITICAL: Disks unknown: 0 | 'disks.total.count'=3;;;0; 'disks.normal.count'=1;;;0;3 'disks.degraded.count'=1;;;0;3 'disks.new.count'=0;;;0;3 'disks.failed.count'=1;;;0;3 'disks.unknown.count'=0;@0:0;;0;3
