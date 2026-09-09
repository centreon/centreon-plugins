*** Settings ***
Documentation       apps::virtualization::vates::xenorchestra::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}..${/}mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::virtualization::vates::xenorchestra::plugin
...                 --mode=status
...                 --password=C3POR2P2
...                 --username=obi-wan
...                 --hostname=127.0.0.1
...                 --proto=http
...                 --port=3000


*** Test Cases ***
Vm Status ${tc}
    [Tags]    apps    virtualization    xenorchestra
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: api returned 'ok'
    ...    2
    ...    --username=wrong-username
    ...    OK: api returned 'invalid credentials'
    ...    3
    ...    --port=3999
    ...    UNKNOWN: curl perform error : Couldn't connect to server
