*** Settings ***
Documentation       notification::orangesms::plugin

Resource            ${CURDIR}${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}orangesms.mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=notification::orangesms::plugin
...                 --mode=alerts
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --username=1
...                 --password=1


*** Test Cases ***
Alerts ${tc}
    [Tags]    notification    orangesms
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_regexp}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_regexp
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    ^UNKNOWN:
    ...    2
    ...    --to=1 --group-id=111 --message=test
    ...    ^OK: message sent #4a0c8b08-cc7e-4cee-a6a5-2407c9cba5d4
