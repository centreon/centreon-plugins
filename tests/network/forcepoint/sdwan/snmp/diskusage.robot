*** Settings ***
Documentation       Forcepoint SD-WAN Mode Diskusage

Resource            ${CURDIR}${/}../..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}                                          ${CENTREON_PLUGINS} --plugin=network::forcepoint::sdwan::snmp::plugin

*** Test Cases ***
Diskusage ${tc}
    [Tags]    network    forcepoint    sdwan     snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=disk-usage
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/forcepoint/sdwan/snmp/forcepoint
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                           expected_result    --
            ...      1     ${EMPTY}                                                OK: All disks are ok | '/dev/XXXX/disc0/XXXX#disk.space.usage.bytes'=484992B;;;0;484992 '/dev/XXXX/disc0/XXXX#disk.space.free.bytes'=0B;;;0;484992 '/dev/XXXX/disc0/XXXX#disk.space.usage.percentage'=100.00%;;;0;100 '/dev/xxx8#disk.space.usage.bytes'=236900B;;;0;1980080 '/dev/xxx8#disk.space.free.bytes'=1743180B;;;0;1980080 '/dev/xxx8#disk.space.usage.percentage'=11.96%;;;0;100 '/dev/xxx9#disk.space.usage.bytes'=406892B;;;0;3286984 '/dev/xxx9#disk.space.free.bytes'=2880092B;;;0;3286984 '/dev/xxx9#disk.space.usage.percentage'=12.38%;;;0;100
            ...      2     --filter-counters=space-usage-prct                      OK: All disks are ok | '/dev/XXXX/disc0/XXXX#disk.space.usage.percentage'=100.00%;;;0;100 '/dev/xxx8#disk.space.usage.percentage'=11.96%;;;0;100 '/dev/xxx9#disk.space.usage.percentage'=12.38%;;;0;100
            ...      3     --warning-space-usage=:10000 --filter-name=XXXX         WARNING: Disk '/dev/XXXX/disc0/XXXX' space usage total: 473.62 KB used: 473.62 KB (100.00%) free: 0.00 B (0.00%) | '/dev/XXXX/disc0/XXXX#disk.space.usage.bytes'=484992B;0:10000;;0;484992 '/dev/XXXX/disc0/XXXX#disk.space.free.bytes'=0B;;;0;484992 '/dev/XXXX/disc0/XXXX#disk.space.usage.percentage'=100.00%;;;0;100
            ...      4     --warning-space-usage-free=:1000 --filter-name=xxx8     WARNING: Disk '/dev/xxx8' space usage total: 1.89 MB used: 231.35 KB (11.96%) free: 1.66 MB (88.04%) | '/dev/xxx8#disk.space.usage.bytes'=236900B;;;0;1980080 '/dev/xxx8#disk.space.free.bytes'=1743180B;0:1000;;0;1980080 '/dev/xxx8#disk.space.usage.percentage'=11.96%;;;0;100
            ...      5     --critical-space-usage-prct=1000: --filter-name=xxx9    CRITICAL: Disk '/dev/xxx9' space usage total: 3.13 MB used: 397.36 KB (12.38%) free: 2.75 MB (87.62%) | '/dev/xxx9#disk.space.usage.bytes'=406892B;;;0;3286984 '/dev/xxx9#disk.space.free.bytes'=2880092B;;;0;3286984 '/dev/xxx9#disk.space.usage.percentage'=12.38%;;1000:;0;100
            ...      6     --filter-name=NOMATCH                                   UNKNOWN: No disk found.
