*** Settings ***
Documentation       Storage Synology SNMP

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}                          ${CENTREON_PLUGINS} --plugin=storage::synology::snmp::plugin

&{check_components_test1}
...                             description=Checking disk components when all disks are ok
...                             snmpcommunity=storage/synology/snmp/synology-disk-ok
...                             expected_output=OK: All 8 components are ok [2/2 disk, 2/2 fan, 1/1 psu, 2/2 raid, 1/1 system]. | 'Disk 1#hardware.disk.bad_sectors.count'=0;;;0; 'Disk 2#hardware.disk.bad_sectors.count'=0;;;0; 'hardware.disk.count'=2;;;; 'hardware.fan.count'=2;;;; 'hardware.psu.count'=1;;;; 'hardware.raid.count'=2;;;; 'hardware.system.count'=1;;;;
&{check_components_test2}
...                             description=Checking disk components when one disks is warning
...                             snmpcommunity=storage/synology/snmp/synology-disk-warning
...                             expected_output=WARNING: Disk 'Disk 2' health is warning | 'Disk 1#hardware.disk.bad_sectors.count'=0;;;0; 'Disk 2#hardware.disk.bad_sectors.count'=0;;;0; 'hardware.disk.count'=2;;;; 'hardware.fan.count'=2;;;; 'hardware.psu.count'=1;;;; 'hardware.raid.count'=2;;;; 'hardware.system.count'=1;;;;
&{check_components_test3}
...                             description=Checking disk components when one disks is critical
...                             snmpcommunity=storage/synology/snmp/synology-disk-critical
...                             expected_output=CRITICAL: Disk 'Disk 2' health is critical | 'Disk 1#hardware.disk.bad_sectors.count'=0;;;0; 'Disk 2#hardware.disk.bad_sectors.count'=0;;;0; 'hardware.disk.count'=2;;;; 'hardware.fan.count'=2;;;; 'hardware.psu.count'=1;;;; 'hardware.raid.count'=2;;;; 'hardware.system.count'=1;;;;
&{check_components_test4}
...                             description=Checking disk components when one disks is failing
...                             snmpcommunity=storage/synology/snmp/synology-disk-failing
...                             expected_output=CRITICAL: Disk 'Disk 2' health is failing | 'Disk 1#hardware.disk.bad_sectors.count'=0;;;0; 'Disk 2#hardware.disk.bad_sectors.count'=0;;;0; 'hardware.disk.count'=2;;;; 'hardware.fan.count'=2;;;; 'hardware.psu.count'=1;;;; 'hardware.raid.count'=2;;;; 'hardware.system.count'=1;;;;
@{check_components_tests}
...                             &{check_components_test1}
...                             &{check_components_test2}
...                             &{check_components_test3}
...                             &{check_components_test4}

&{uptime_t1}
...                             description=Uptime check expected to be OK
...                             snmpcommunity=storage/synology/snmp/synology-disk-ok
...                             warning=
...                             critical=
...                             expected_output=OK: System uptime is: 46m 5s | 'uptime'=2765.00s;;;0;
&{uptime_t2}
...                             description=Uptime check expected to be warning
...                             snmpcommunity=storage/synology/snmp/synology-disk-ok
...                             warning=10
...                             critical=
...                             expected_output=WARNING: System uptime is: 46m 5s | 'uptime'=2765.00s;0:10;;0;
&{uptime_t3}
...                             description=Uptime check expected to be critical
...                             snmpcommunity=storage/synology/snmp/synology-disk-ok
...                             warning=
...                             critical=10
...                             expected_output=CRITICAL: System uptime is: 46m 5s | 'uptime'=2765.00s;;0:10;0;

@{uptime_tests}
...                             &{uptime_t1}
...                             &{uptime_t2}
...                             &{uptime_t3}


*** Test Cases ***
Components
    [Tags]    storage    synology    snmp
    FOR    ${check_components_test}    IN    @{check_components_tests}
        ${command}    Catenate
        ...    ${CMD}
        ...    --mode=components
        ...    --hostname=127.0.0.1
        ...    --snmp-version=2
        ...    --snmp-port=2024
        ...    --snmp-community=${check_components_test.snmpcommunity}

        ${output}    Run    ${command}
        Should Be Equal As Strings
        ...    ${check_components_test.expected_output}
        ...    ${output}
        ...    ${check_components_test.description} failed. Wrong output for components mode: ${check_components_test}.{\n}Command output:{\n}${output}
    END

Uptime
    [Tags]    storage    synology    snmp
    FOR    ${test_item}    IN    @{uptime_tests}
        ${command}    Catenate
        ...    ${CMD}
        ...    --mode=uptime
        ...    --hostname=127.0.0.1
        ...    --snmp-version=2
        ...    --snmp-port=2024
        ...    --snmp-community=${test_item.snmpcommunity}
        ...    --warning-uptime=${test_item.warning}
        ...    --critical-uptime=${test_item.critical}

        ${output}    Run    ${command}
        Should Be Equal As Strings
        ...    ${test_item.expected_output}
        ...    ${output}
        ...    ${test_item.description} failed. Wrong output for components mode: ${test_item}.{\n}Command output:{\n}${output}
    END
