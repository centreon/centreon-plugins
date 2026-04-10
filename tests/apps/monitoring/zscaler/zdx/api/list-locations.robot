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
...                 --mode=list-locations
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --client-id=1
...                 --client-secret=1
...                 --auth-url=http://${HOSTNAME}:${APIPORT}/oauth2/v1/token


*** Test Cases ***
List-Locations ${tc}
    [Tags]    apps    monitoring    api
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    List locations [id: 73260557] [name: Columbus Office] [id: 4294967293] [name: Road Warrior]
