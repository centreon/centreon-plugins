*** Settings ***
Documentation       apps::vmware::vsphere8::vcsa::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...         --plugin=apps::vmware::vsphere8::vcsa::plugin
...         --mode=interfaces
...         --hostname=${HOSTNAME}
...         --port=${APIPORT}
...         --proto=http
...         --username=1
...         --password=1


*** Test Cases ***
Interfaces ${tc}
    [Tags]    apps    vmware    vcsa
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
    ...    CRITICAL: interface "nic1" is down in "STATIC" mode with address "172.16.12.3"
    ...    2
    ...    --interface-name=nic0
    ...    OK: interface "nic0" is up in "STATIC" mode with address "172.16.99.20"
    ...    3
    ...    --include-name=1
    ...    CRITICAL: interface "nic1" is down in "STATIC" mode with address "172.16.12.3"
    ...    4
    ...    --exclude-name=1
    ...    OK: interface "nic0" is up in "STATIC" mode with address "172.16.12.2"
    ...    5
    ...    --include-mac=1
    ...    CRITICAL: interface "nic1" is down in "STATIC" mode with address "172.16.12.3"
    ...    6
    ...    --exclude-mac=1
    ...    UNKNOWN: No service found with current filters.
    ...    7
    ...    --include-ipv4-address=3
    ...    CRITICAL: interface "nic1" is down in "STATIC" mode with address "172.16.12.3"
    ...    8
    ...    --exclude-ipv4-address=3
    ...    OK: interface "nic0" is up in "STATIC" mode with address "172.16.12.2"
    ...    9
    ...    --include-ipv4-mode=STATIC
    ...    CRITICAL: interface "nic1" is down in "STATIC" mode with address "172.16.12.3"
    ...    10
    ...    --exclude-ipv4-mode=STATIC
    ...    UNKNOWN: No service found with current filters.
    ...    11
    ...    --include-status=up
    ...    OK: interface "nic0" is up in "STATIC" mode with address "172.16.12.2"
    ...    12
    ...    --exclude-status=up
    ...    CRITICAL: interface "nic1" is down in "STATIC" mode with address "172.16.12.3"
    ...    13
    ...    --critical-status=0
    ...    WARNING: interface "nic1" is down in "STATIC" mode with address "172.16.12.3"
    ...    14
    ...    --critical-status=1 --include-status=up
    ...    CRITICAL: interface "nic0" is up in "STATIC" mode with address "172.16.12.2"
