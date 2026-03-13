*** Settings ***
Documentation       Tests for deep JSON path traversal in HTTP Collection mode

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}collection-deep-path.mockoon.json

${CMD}              ${CENTREON_PLUGINS} --plugin=apps::protocols::http::plugin
...                 --mode collection
...                 --constant='hostname=${HOSTNAME}'
...                 --constant='protocol=http'
...                 --constant='port=${APIPORT}'


*** Test Cases ***
Check if ${test_desc}
    [Tags]    collections    http
    ${command}    Catenate
    ...    ${CMD}    --config=${CURDIR}/${collection}
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    test_desc                          collection                                               expected_result   --
        ...      nested JSON paths are traversed    collection-deep-path-check-nested.collection.json        WARNING: server1: dc=dc1, row=A, slot=42 - server2: dc=dc2, row=B, slot=7 | 'items.count'=2;;;0;
