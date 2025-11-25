*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}Mockoon.json

${cmd}              ${CENTREON_PLUGINS}
...                 --plugin=network::stormshield::api::plugin
...                 --mode=list-vpn-tunnels
...                 --custommode=api
...                 --hostname=${HOSTNAME}
...                 --api-username=username
...                 --api-password=password
...                 --proto=http
...                 --port=${APIPORT}
...                 --timeout=5


*** Test Cases ***
list-vpn-tunnels ${tc}
    [Tags]    network    api
    ${output}    Run    ${CMD} ${extraoptions} | wc -l

    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    ${expected_result}
    ...    Wrong output result for command:\n${CMD} ${extraoptions}\n\nObtained:\n${output}\n\nExpected:\n${expected_result}\n
    ...    values=False
    ...    collapse_spaces=True

    Examples:    tc    extraoptions       expected_result   --
        ...      1     ${EMPTY}           24
