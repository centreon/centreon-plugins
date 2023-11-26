*** Settings ***
Documentation       Storage Synology SNMP

Library             OperatingSystem
Library             XML

Test Timeout        120s


*** Variables ***
${CENTREON_PLUGINS}         ${CURDIR}${/}..${/}..${/}..${/}src${/}centreon_plugins.pl

${CMD}                      perl ${CENTREON_PLUGINS} --plugin=storage::synology::snmp::plugin

&{check_components_test1}
...                         snmpcommunity=synology_component_disk_ok
...                         expected_output="OK: All 8 components are ok [2/2 disk, 2/2 fan, 1/1 psu, 2/2 raid, 1/1 system]. "
&{check_components_test2}
...                         snmpcommunity=synology_component_disk_warning
...                         expected_output="WARNING: Disk 'Disk 2' health is warning"
&{check_components_test3}
...                         snmpcommunity=synology_component_disk_critical
...                         expected_output="CRITICAL: Disk 'Disk 2' health is critical "
&{check_components_test4}
...                         snmpcommunity=synology_component_disk_failing
...                         expected_output="CRITICAL: Disk 'Disk 2' health is failing "
@{check_components_tests}
...                         &{check_components_test1}
...                         &{check_components_test2}
...                         &{check_components_test3}
...                         &{check_components_test4}


*** Test Cases ***
Synology SNMP check disk components
    [Documentation]    Monitor the different states of disk health
    [Tags]    storage   synology    snmp
    FOR    ${check_components_test}    IN    @{check_components_tests}
        ${command}    Catenate
        ...    ${CMD}
        ...    --mode=components
        ...    --hostname=127.0.0.1
        ...    --snmp-version=2
        ...    --snmp-port=2024
        ${command}    Catenate    ${command}    --snmp-community=${check_components_test.snmpcommunity}
        ${output}    Run    ${command}
        Log To Console    ${command}
        ${nb_results}    Get Element Count
        ...    ${output}
        ...    label
        Should Be Equal As Integers
        ...    ${check_components_test.expected_output}
        ...    ${output}
        ...    Wrong output for components mode: ${check_components_test}.{\n}Command output:{\n}${output}
    END
