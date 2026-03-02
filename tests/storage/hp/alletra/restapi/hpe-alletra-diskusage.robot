*** Settings ***
Documentation       HPE Alletra Storage REST API Mode Disk Usage

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
...                 --mode disk-usage
...                 --hostname=${HOSTNAME}
...                 --api-username=xx
...                 --api-password=xx
...                 --proto=http
...                 --port=${APIPORT}


*** Test Cases ***
DiskUsage ${tc}
    [Tags]    storage    api    hpe    hp
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_regexp}

    Examples:        tc       extraoptions                                                              expected_regexp    --
            ...      1        ${EMPTY}                                                                  OK: Total Used: 28.04 TB / 41.91 TB, Total percentage used: 66.91 %, Total Free: 13.87 TB - All disks are ok | 'disks.total.space.usage.bytes'=30830348992512;;;0;46076409151488 'disks.total.space.usage.percent'=66.9113534675615;;;0;100 'disks.total.space.free.bytes'=15246060158976;;;0;46076409151488 '0#disk.space.usage.bytes'=10276782997504B;;;0;15358803050496 '0#disk.space.free.bytes'=10276782997504B;;;0;15358803050496 '0#disk.space.usage.percentage'=66.91%;;;0;100 '1#disk.space.usage.bytes'=10276782997504B;;;0;15358803050496 '1#disk.space.free.bytes'=10276782997504B;;;0;15358803050496 '1#disk.space.usage.percentage'=66.91%;;;0;100 '2#disk.space.usage.bytes'=10276782997504B;;;0;15358803050496 '2#disk.space.free.bytes'=10276782997504B;;;0;15358803050496 '2#disk.space.usage.percentage'=66.91%;;;0;100
            ...      2        --filter-id='^0$'                                                         OK: Total Used: 9.35 TB / 13.97 TB, Total percentage used: 66.91 %, Total Free: 4.62 TB - Disk #0 (XXXX1/XXXXXX1, serial: XXXXX1) located 1:1 has Used: 9.35 TB of 13.97 TB (66.91%) Free: 4.62 TB (33.09%) | 'disks.total.space.usage.bytes'=10276782997504;;;0;15358803050496 'disks.total.space.usage.percent'=66.9113534675615;;;0;100 'disks.total.space.free.bytes'=5082020052992;;;0;15358803050496 '0#disk.space.usage.bytes'=10276782997504B;;;0;15358803050496 '0#disk.space.free.bytes'=10276782997504B;;;0;15358803050496 '0#disk.space.usage.percentage'=66.91%;;;0;100
            ...      3        --filter-manufacturer='X1$'                                               OK: Total Used: 9.35 TB / 13.97 TB, Total percentage used: 66.91 %, Total Free: 4.62 TB - Disk #0 (XXXX1/XXXXXX1, serial: XXXXX1) located 1:1 has Used: 9.35 TB of 13.97 TB (66.91%) Free: 4.62 TB (33.09%) | 'disks.total.space.usage.bytes'=10276782997504;;;0;15358803050496 'disks.total.space.usage.percent'=66.9113534675615;;;0;100 'disks.total.space.free.bytes'=5082020052992;;;0;15358803050496 '0#disk.space.usage.bytes'=10276782997504B;;;0;15358803050496 '0#disk.space.free.bytes'=10276782997504B;;;0;15358803050496 '0#disk.space.usage.percentage'=66.91%;;;0;100
            ...      4        --filter-model='X1$'                                                      OK: Total Used: 9.35 TB / 13.97 TB, Total percentage used: 66.91 %, Total Free: 4.62 TB - Disk #0 (XXXX1/XXXXXX1, serial: XXXXX1) located 1:1 has Used: 9.35 TB of 13.97 TB (66.91%) Free: 4.62 TB (33.09%) | 'disks.total.space.usage.bytes'=10276782997504;;;0;15358803050496 'disks.total.space.usage.percent'=66.9113534675615;;;0;100 'disks.total.space.free.bytes'=5082020052992;;;0;15358803050496 '0#disk.space.usage.bytes'=10276782997504B;;;0;15358803050496 '0#disk.space.free.bytes'=10276782997504B;;;0;15358803050496 '0#disk.space.usage.percentage'=66.91%;;;0;100
            ...      5        --filter-serial='X2$'                                                     OK: Total Used: 9.35 TB / 13.97 TB, Total percentage used: 66.91 %, Total Free: 4.62 TB - Disk #1 (XXXX2/XXXX2, serial: XXXX2) located 1:2 has Used: 9.35 TB of 13.97 TB (66.91%) Free: 4.62 TB (33.09%) | 'disks.total.space.usage.bytes'=10276782997504;;;0;15358803050496 'disks.total.space.usage.percent'=66.9113534675615;;;0;100 'disks.total.space.free.bytes'=5082020052992;;;0;15358803050496 '1#disk.space.usage.bytes'=10276782997504B;;;0;15358803050496 '1#disk.space.free.bytes'=10276782997504B;;;0;15358803050496 '1#disk.space.usage.percentage'=66.91%;;;0;100
            ...      6        --filter-position=1:2                                                     OK: Total Used: 9.35 TB / 13.97 TB, Total percentage used: 66.91 %, Total Free: 4.62 TB - Disk #1 (XXXX2/XXXX2, serial: XXXX2) located 1:2 has Used: 9.35 TB of 13.97 TB (66.91%) Free: 4.62 TB (33.09%) | 'disks.total.space.usage.bytes'=10276782997504;;;0;15358803050496 'disks.total.space.usage.percent'=66.9113534675615;;;0;100 'disks.total.space.free.bytes'=5082020052992;;;0;15358803050496 '1#disk.space.usage.bytes'=10276782997504B;;;0;15358803050496 '1#disk.space.free.bytes'=10276782997504B;;;0;15358803050496 '1#disk.space.usage.percentage'=66.91%;;;0;100
            ...      7        --filter-counters='^usage$' --critical-usage=:10                          CRITICAL: Disk #0 (XXXX1/XXXXXX1, serial: XXXXX1) located 1:1 has Used: 9.35 TB of 13.97 TB (66.91%) Free: 4.62 TB (33.09%) - Disk #1 (XXXX2/XXXX2, serial: XXXX2) located 1:2 has Used: 9.35 TB of 13.97 TB (66.91%) Free: 4.62 TB (33.09%) - Disk #2 (XXX3/XXX3, serial: XXX3) located 1:3 has Used: 9.35 TB of 13.97 TB (66.91%) Free: 4.62 TB (33.09%) | '0#disk.space.usage.bytes'=10276782997504B;;0:10;0;15358803050496 '1#disk.space.usage.bytes'=10276782997504B;;0:10;0;15358803050496 '2#disk.space.usage.bytes'=10276782997504B;;0:10;0;15358803050496
            ...      8        --filter-counters='usage-free' --critical-usage-free=:10                  CRITICAL: Disk #0 (XXXX1/XXXXXX1, serial: XXXXX1) located 1:1 has Used: 9.35 TB of 13.97 TB (66.91%) Free: 4.62 TB (33.09%) - Disk #1 (XXXX2/XXXX2, serial: XXXX2) located 1:2 has Used: 9.35 TB of 13.97 TB (66.91%) Free: 4.62 TB (33.09%) - Disk #2 (XXX3/XXX3, serial: XXX3) located 1:3 has Used: 9.35 TB of 13.97 TB (66.91%) Free: 4.62 TB (33.09%) | '0#disk.space.free.bytes'=10276782997504B;;0:10;0;15358803050496 '1#disk.space.free.bytes'=10276782997504B;;0:10;0;15358803050496 '2#disk.space.free.bytes'=10276782997504B;;0:10;0;15358803050496
            ...      9        --filter-counters='usage-prct' --warning-usage-prct=:10                   WARNING: Disk #0 (XXXX1/XXXXXX1, serial: XXXXX1) located 1:1 has Used : 66.91 % - Disk #1 (XXXX2/XXXX2, serial: XXXX2) located 1:2 has Used : 66.91 % - Disk #2 (XXX3/XXX3, serial: XXX3) located 1:3 has Used : 66.91 % | 'disks.total.space.usage.percent'=66.9113534675615;;;0;100 '0#disk.space.usage.percentage'=66.91%;0:10;;0;100 '1#disk.space.usage.percentage'=66.91%;0:10;;0;100 '2#disk.space.usage.percentage'=66.91%;0:10;;0;100
            ...      10       --filter-counters='total-free' --warning-total-free=:10                   WARNING: Total Free: 13.87 TB | 'disks.total.space.free.bytes'=15246060158976;0:10;;0;46076409151488
            ...      11       --filter-counters='total-usage' --warning-total-usage=:10                 WARNING: Total Used: 28.04 TB / 41.91 TB | 'disks.total.space.usage.bytes'=30830348992512;0:10;;0;46076409151488 'disks.total.space.usage.percent'=66.9113534675615;;;0;100
            ...      12       --filter-counters='total-usage-prct' --critical-total-usage-prct=:60      CRITICAL: Total percentage used: 66.91 % | 'disks.total.space.usage.percent'=66.9113534675615;;0:60;0;100
