*** Settings ***


Resource            ${CURDIR}${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}ipfabric.mockoon.json

${CMD}              ${CENTREON_PLUGINS} --plugin=apps::ipfabric::plugin
...                 --api-key=EEECGFCGFCGF
...                 --mode=discovery
...                 --http-peer-addr=127.0.0.1
...                 --proto=http
...                 --port=3000
...                 --prettify

*** Test Cases ***
Discovery ${tc}
    [Tags]    apps    api    ipfabric
    ${command}    Catenate    ${CMD}
    ...     --hostname=${server_name}
    
    ${output}    Run    ${command} | wc -l

    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    ${expected_result}
    ...    Wrong output result for command:\n${command}\n\nObtained:\n${output}\n\nExpected:\n${expected_result}\n
    ...    values=False
    ...    collapse_spaces=True
    
    Examples:    tc    server_name              expected_result   --
        ...      1     cisco-live02.ipf.cx      5468
        ...      2     demo1.eu.ipfabric.io     99

