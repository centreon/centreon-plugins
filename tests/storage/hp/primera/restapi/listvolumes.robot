*** Settings ***
Documentation       HPE Primera Storage REST API

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}hpe-primera.mockoon.json
${HOSTNAME}             127.0.0.1
${APIPORT}              3000
${CMD}              ${CENTREON_PLUGINS} 
...                 --plugin=storage::hp::primera::restapi::plugin
...                 --mode=list-volumes
...                 --hostname=${HOSTNAME}
...                 --api-username=toto
...                 --api-password=toto
...                 --proto=http
...                 --port=${APIPORT}
...                 --custommode=api
...                 --statefile-dir=/dev/shm/
...                 

*** Test Cases ***
List-Volumes ${tc}
    [Tags]    storage     api    hpe    hp
    ${output}    Run    ${CMD} ${extraoptions} | wc -l

    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    ${expected_result}
    ...    Wrong output result for command:\n${CMD} ${extraoptions}\n\nObtained:\n${output}\n\nExpected:\n${expected_result}\n
    ...    values=False
    ...    collapse_spaces=True


    Examples:    tc    extraoptions       expected_result   --
        ...      1     ${EMPTY}           18
        ...      2     --disco-show       20
        ...      3     --disco-format     7
