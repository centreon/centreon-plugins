*** Settings ***


Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json

${CMD}              ${CENTREON_PLUGINS} --plugin=apps::vmware::vsphere8::esx::plugin
...                 --password=C3POR2P2
...                 --username=obi-wan
...                 --mode=discovery
...                 --hostname=127.0.0.1
...                 --proto=http
...                 --port=3000

*** Test Cases ***
Discovery ${tc}
    [Tags]    apps    api    vmware   vsphere8    esx    discovery
    ${command}    Catenate    ${CMD} --http-backend=${http_backend}
    
    # We sort the host names and keep only the last one and make sure it is the expected one
    ${output}    Run    ${command} | jq -r '.results | .[].host_name' | sort | tail -1

    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    ${expected_result}
    ...    Wrong output result for command:\n${command}\n\nObtained:\n${output}\n\nExpected:\n${expected_result}\n
    ...    values=False
    ...    collapse_spaces=True
    
    
    Examples:    tc    http_backend     expected_result   --
        ...      1     curl             esx3.acme.com
        ...      2     lwp              esx3.acme.com

