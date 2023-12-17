*** Settings ***
Documentation       Storage Synology SNMP

Resource            ${CURDIR}${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}                      perl ${CENTREON_PLUGINS} --plugin=storage::synology::snmp::plugin

&{check_components_test1}
...                         description=Checking disk components when all disks are ok
...                         snmpcommunity=synology_component_disk_ok
...                         expected_output=OK: All 8 components are ok [2/2 disk, 2/2 fan, 1/1 psu, 2/2 raid, 1/1 system]. | 'Disk 1#hardware.disk.bad_sectors.count'=0;;;0; 'Disk 2#hardware.disk.bad_sectors.count'=0;;;0; 'hardware.disk.count'=2;;;; 'hardware.fan.count'=2;;;; 'hardware.psu.count'=1;;;; 'hardware.raid.count'=2;;;; 'hardware.system.count'=1;;;;
&{check_components_test2}
...                         description=Checking disk components when one disks is warning
...                         snmpcommunity=synology_component_disk_warning
...                         expected_output=WARNING: Disk 'Disk 2' health is warning | 'Disk 1#hardware.disk.bad_sectors.count'=0;;;0; 'Disk 2#hardware.disk.bad_sectors.count'=0;;;0; 'hardware.disk.count'=2;;;; 'hardware.fan.count'=2;;;; 'hardware.psu.count'=1;;;; 'hardware.raid.count'=2;;;; 'hardware.system.count'=1;;;;
&{check_components_test3}
...                         description=Checking disk components when one disks is critical
...                         snmpcommunity=synology_component_disk_critical
...                         expected_output=CRITICAL: Disk 'Disk 2' health is critical | 'Disk 1#hardware.disk.bad_sectors.count'=0;;;0; 'Disk 2#hardware.disk.bad_sectors.count'=0;;;0; 'hardware.disk.count'=2;;;; 'hardware.fan.count'=2;;;; 'hardware.psu.count'=1;;;; 'hardware.raid.count'=2;;;; 'hardware.system.count'=1;;;;
&{check_components_test4}
...                         description=Checking disk components when one disks is failing
...                         snmpcommunity=synology_component_disk_failing
...                         expected_output=CRITICAL: Disk 'Disk 2' health is failing | 'Disk 1#hardware.disk.bad_sectors.count'=0;;;0; 'Disk 2#hardware.disk.bad_sectors.count'=0;;;0; 'hardware.disk.count'=2;;;; 'hardware.fan.count'=2;;;; 'hardware.psu.count'=1;;;; 'hardware.raid.count'=2;;;; 'hardware.system.count'=1;;;;
@{check_components_tests}
...                         &{check_components_test1}
...                         &{check_components_test2}
...                         &{check_components_test3}
...                         &{check_components_test4}


*** Test Cases ***
Synology SNMP: Checking disk components
    [Documentation]    Monitor the different states of disk health
    [Tags]    storage   synology    snmp
    Log To Console    Synology SNMP: Checking disk components
    FOR    ${check_components_test}    IN    @{check_components_tests}
        ${command}    Catenate
        ...    ${CMD}
        ...    --mode=components
        ...    --hostname=127.0.0.1
        ...    --snmp-version=2
        ...    --snmp-port=2024
        ...    --snmp-community=${check_components_test.snmpcommunity}
        ${output}    Run    ${command}
        Log To Console    ${check_components_test.description}
        Should Be Equal As Strings
        ...    ${check_components_test.expected_output}
        ...    ${output}
        ...    Wrong output for components mode: ${check_components_test}.{\n}Command output:{\n}${output}
    END
