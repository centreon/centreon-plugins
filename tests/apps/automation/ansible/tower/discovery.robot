*** Settings ***
Documentation       Check the discovery mode with api custom mode

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}ansible_tower.json

${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::automation::ansible::tower::plugin
...                 --custommode=api
...                 --hostname=${HOSTNAME}
...                 --username=username
...                 --password=password
...                 --port=${APIPORT}
...                 --mode=discovery

*** Test Cases ***
Discovery ${tc}
    [Tags]    apps    automation    ansible    api
    
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extraoptions}

    ${output}    Run    ${command}

    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    ${expected_result}
    ...    Wrong output result for command:\n${CMD}\n\nObtained:\n${output}\n\nExpected:\n${expected_result}\n
    ...    values=False
    ...    collapse_spaces=True

    Examples:    tc    extraoptions                expected_result   --
        ...      1     | jq '.results | length'    10
        ...      2     | jq -r '.results | map(select(.ansible_host != "" and (.ansible_host | test("^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$") | not))) | .[].ansible_host'    ${EMPTY}
