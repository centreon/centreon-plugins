*** Settings ***
Documentation       Check the list-diskio mode

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}                  ${CENTREON_PLUGINS} --plugin=os::linux::snmp::plugin


*** Test Cases ***
List diskio ${tc}
    [Documentation]    Check the number of returned disks
    [Tags]    os    linux    snmp    service-disco
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-diskio
    ...    --hostname=127.0.0.1
    ...    --snmp-version=2
    ...    --snmp-port=2024
    ...    --disco-show
    ...    --snmp-community=${snmpcommunity}
    ${output}    Run    ${command}
    ${nb_results}    Get Element Count
    ...    ${output}
    ...    label
    Should Be Equal As Integers
    ...    ${expected_result}
    ...    ${nb_results}
    ...    Wrong output result for command:{\n}{\n}${command}{\n}{\n}Command output:{\n}{\n}${output}

    Examples:         tc  snmpcommunity                     expected_result    --
            ...       1   os/linux/snmp/list-diskio         10                 
            ...       2   os/linux/snmp/list-diskio-2       4                   