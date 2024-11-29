*** Settings ***
Documentation       Storage Synology SNMP

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}                          ${CENTREON_PLUGINS} --plugin=storage::synology::snmp::plugin

*** Test Cases ***
Components ${tc}
    [Tags]    storage    synology    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=components
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=${snmpcommunity}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    snmpcommunity                                               expected_result    --
            ...      1     storage/synology/snmp/synology-disk-ok                      OK: All 8 components are ok [2/2 disk, 2/2 fan, 1/1 psu, 2/2 raid, 1/1 system]. | 'Disk 1#hardware.disk.bad_sectors.count'=0;;;0; 'Disk 2#hardware.disk.bad_sectors.count'=0;;;0; 'hardware.disk.count'=2;;;; 'hardware.fan.count'=2;;;; 'hardware.psu.count'=1;;;; 'hardware.raid.count'=2;;;; 'hardware.system.count'=1;;;;
            ...      2     storage/synology/snmp/synology-disk-warning                 WARNING: Disk 'Disk 2' health is warning | 'Disk 1#hardware.disk.bad_sectors.count'=0;;;0; 'Disk 2#hardware.disk.bad_sectors.count'=0;;;0; 'hardware.disk.count'=2;;;; 'hardware.fan.count'=2;;;; 'hardware.psu.count'=1;;;; 'hardware.raid.count'=2;;;; 'hardware.system.count'=1;;;;
            ...      3     storage/synology/snmp/synology-disk-critical                CRITICAL: Disk 'Disk 2' health is critical | 'Disk 1#hardware.disk.bad_sectors.count'=0;;;0; 'Disk 2#hardware.disk.bad_sectors.count'=0;;;0; 'hardware.disk.count'=2;;;; 'hardware.fan.count'=2;;;; 'hardware.psu.count'=1;;;; 'hardware.raid.count'=2;;;; 'hardware.system.count'=1;;;;
            ...      4     storage/synology/snmp/synology-disk-failing                 CRITICAL: Disk 'Disk 2' health is failing | 'Disk 1#hardware.disk.bad_sectors.count'=0;;;0; 'Disk 2#hardware.disk.bad_sectors.count'=0;;;0; 'hardware.disk.count'=2;;;; 'hardware.fan.count'=2;;;; 'hardware.psu.count'=1;;;; 'hardware.raid.count'=2;;;; 'hardware.system.count'=1;;;;