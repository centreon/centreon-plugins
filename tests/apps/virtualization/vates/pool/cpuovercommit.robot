*** Settings ***
Documentation       apps::virtualization::vates::pool::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}..${/}mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::virtualization::vates::pool::plugin
...                 --mode=cpu-over-commit
...                 --password=C3POR2P2
...                 --username=obi-wan
...                 --hostname=127.0.0.1
...                 --proto=http
...                 --port=3000


*** Test Cases ***
Cpu over commit ${tc}
    [Tags]    apps    virtualization    vm
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
    ...    UNKNOWN: you must fill either --pool-uuid or --pool-name.
    ...    2
    ...    --pool-uuid=00969214-df4d-83cb-78d5-bec9181903d4
    ...    OK: CPU overcommit ratio is 25.00 % | 'pool.cpu.overcommit.percentage'=25.00%;0:90;0:100;0;
    ...    3
    ...    --pool-name=vates
    ...    OK: CPU overcommit ratio is 25.00 % | 'pool.cpu.overcommit.percentage'=25.00%;0:90;0:100;0;
