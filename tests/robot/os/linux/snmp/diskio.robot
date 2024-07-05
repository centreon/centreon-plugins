*** Settings ***
Documentation       OS Linux SNMP plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}                  ${CENTREON_PLUGINS} --plugin=os::linux::snmp::plugin


*** Test Cases ***
Linux SNMP list diskio devices ${documentation} ${tc}/2
    [Tags]    os    linux    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-diskio
    ...    --hostname=127.0.0.1
    ...    --snmp-version=2
    ...    --snmp-port=2024
    ...    --disco-show
    ...    --snmp-community=${snmpcommunity}
    ${output}    Run    ${command}
    Log To Console    ${command}
    ${nb_results}    Get Element Count
    ...    ${output}
    ...    label
    Should Be Equal As Integers
    ...    ${expected_result}
    ...    ${nb_results}
    ...    Wrong output result for list diskio devices: ${snmpcommunity}.{\n}Command output:{\n}${output}

    Examples:         documentation    tc  snmpcommunity                     expected_result    --
            ...       First run        1   os/linux/snmp/list-diskio         10                 
            ...       Second run       2   os/linux/snmp/list-diskio-2       4                   