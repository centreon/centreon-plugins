*** Settings ***
Documentation       Tests boolean2integer

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

# Suite Setup    Start Mockoon    ${MOCKOON_JSON}
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

    Examples:
    ...    test_desc
    ...    collection
    ...    expected_result
    ...    --
    ...    bool as int anywhere
    ...    collection-boolean2integer.collection.json
    ...    CRITICAL: interruptor '1' switch enabled: 0 - interruptor '2' switch enabled: 1 | '1#interruptor.enabled.count'=0;;;; '2#interruptor.enabled.count'=1;;;;
