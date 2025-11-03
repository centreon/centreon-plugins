*** Settings ***
Documentation       Quanta

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}quanta.mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::monitoring::quanta::restapi::plugin
...                 --hostname=${HOSTNAME}
...                 --api-token=PaSsWoRd
...                 --site-id=10
...                 --proto=http
...                 --port=${APIPORT}


*** Test Cases ***
ListUserJourneys ${tc}
    [Tags]    quanta    api
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-user-journeys
    ...    ${extra_options}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_regexp}
    Examples:        tc       extraoptions                                          expected_regexp    --
            ...      1        ${EMPTY}                                              ^User journeys:
