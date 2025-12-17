*** Settings ***
Documentation       apps::monitoring::zscaler::zdx::api::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::monitoring::zscaler::zdx::api::plugin
...                 --mode=discovery
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --key-id=1
...                 --key-secret=1
${EXPECTED_RESULT}  SEPARATOR=
...                 {"discovered_items":2,"end_time":1765545358,"results":[{"id": 18, "name": "appli_18"}, {"name": \
...                 "appli_42", "id": 42}],"duration":0,"start_time":1765545358}


*** Test Cases ***
Discovery
    [Tags]    apps    monitoring    api
    ${command}    Catenate
    ...    ${CMD}

    Ctn Run Command And Check Result As Json
    ...    ${command}
    ...    ${EXPECTED_RESULT}
