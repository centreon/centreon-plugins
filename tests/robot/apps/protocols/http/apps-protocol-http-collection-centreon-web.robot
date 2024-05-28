*** Settings ***
Documentation       Collections of HTTP Protocol plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}apps-protocol-http-collection-centreon-web.mockoon.json

${CMD}              ${CENTREON_PLUGINS} --plugin  apps::protocols::http::plugin --mode collection
...    --constant='hostname=127.0.0.1' --constant='protocol=http' --constant='port=3000'
...    --constant='username=admin' --constant='password=myPassword'


*** Test Cases ***
Test if ${test_desc}
    [Tags]    Centreon    Collections   HTTP
    ${output}    Run
    ...    ${CMD} --config=${CURDIR}/${collection}
    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    ${expected}
    ...    Wrong output result:\n\n ${output}\nInstead of:\n ${expected}\n\n

    Examples:    test_desc    collection    expected   --
        ...      authentication succeeds    apps-protocol-http-collection-centreon-web-check-auth.collection.json    OK: Authentication resulted in 200 HTTP code
