*** Settings ***
Documentation       apps::virtualization::vates::vm::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}..${/}mockoon.json
${CMD}              ${CENTREON_PLUGINS} --plugin=apps::virtualization::vates::vm::plugin
...                 --mode=status
...                 --password=C3POR2P2
...                 --username=obi-wan
...                 --hostname=127.0.0.1
...                 --proto=http
...                 --port=3000


*** Test Cases ***
Status ${tc}
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
    ...    UNKNOWN: you must fill either --vm-uuid or --vm-name.
    ...    2
    ...    --vm-uuid=e9425768-75ed-a6da-bd00-2774c94ef200
    ...    OK: 'XOA' vm is Running. OS : Debian 12
    ...    3
    ...    --vm-name=XOA
    ...    OK: 'XOA' vm is Running. OS : Debian 12
    ...    4
    ...    --vm-name=XOA --warning-status='\\\%{power_state} =~ /^Running/i'
    ...    WARNING: 'XOA' vm is Running. OS : Debian 12
    ...    5
    ...    --vm-name=XOA --critical-status='\\\%{power_state} =~ /^Running/i'
    ...    CRITICAL: 'XOA' vm is Running. OS : Debian 12
    ...    6
    ...    --vm-name=DontExist
    ...    UNKNOWN: no vm found, api did not return an array with one element. Please check --vm-uuid and --vm-name parameter or --debug.
