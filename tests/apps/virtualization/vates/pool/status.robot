*** Settings ***
Documentation       apps::virtualization::vates::vm::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}..${/}mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::virtualization::vates::pool::plugin
...                 --mode=status
...                 --password=C3POR2P2
...                 --username=obi-wan
...                 --hostname=127.0.0.1
...                 --proto=http
...                 --port=3000


*** Test Cases ***
pool status ${tc}
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
    ...    OK: pool 'vates' master 'vates' is Running - pool has HA enabled
    ...    3
    ...    --pool-name=vates
    ...    OK: pool 'vates' master 'vates' is Running - pool has HA enabled
    ...    4
    ...    --pool-name=second --is-ha='false'
    ...    OK: pool 'second' master 'vates' is Running - pool has HA disabled
    ...    5
    ...    --pool-name=second --is-ha='true'
    ...    CRITICAL: pool has HA disabled
    ...    4
    ...    --pool-name=second --is-ha=''
    ...    CRITICAL: pool has HA disabled
