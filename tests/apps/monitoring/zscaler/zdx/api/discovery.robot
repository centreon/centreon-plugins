*** Settings ***
Documentation       apps::monitoring::zscaler::zdx::api::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}         ${CURDIR}${/}mockoon.json
${CMD}                  ${CENTREON_PLUGINS}
...                     --plugin=apps::monitoring::zscaler::zdx::api::plugin
...                     --mode=discovery
...                     --hostname=${HOSTNAME}
...                     --port=${APIPORT}
...                     --proto=http
...                     --client-id=1
...                     --client-secret=1
...                     --auth-url=http://127.0.0.1:${APIPORT}/oauth2/v1/token

${EXPECTED_RESULT}
...    SEPARATOR=
...    {"discovered_items":2,"end_time":1765545358,"results":[{"hostname": "127.0.0.1", "id": 1, "name": \
...    "SharePoint Online", "score": 73.1244323342416, "total_users": 50}, {"hostname": "127.0.0.1", \
...    "id": 3, "name": "Outlook Online", "score": 81.551724137931, "total_users": 67}],"duration":0, \
...    "start_time":1765545358}


*** Test Cases ***
Discovery
    [Tags]    apps    monitoring    api
    ${command}    Catenate
    ...    ${CMD}

    Ctn Run Command And Check Result As Json
    ...    ${command}
    ...    ${EXPECTED_RESULT}
