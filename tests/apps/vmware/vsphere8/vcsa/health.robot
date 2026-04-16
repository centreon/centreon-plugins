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
...         --mode=health
...         --hostname=${HOSTNAME}
...         --port=${APIPORT}
...         --proto=http
...         --username=1
...         --password=1


*** Test Cases ***
Health ${tc}
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
    ...    CRITICAL: "database-storage" is "red" WARNING: "applmgmt" is "yellow" - "software-packages" is "orange" - "storage" is "gray"
    ...    2
    ...    --include-check=system
    ...    OK: "system" is "green"
    ...    3
    ...    --exclude-check='(applmgmt|database-storage|software-packages|storage)'
    ...    OK: All health checks are OK
    ...    4
    ...    --include-check=applmgmt
    ...    WARNING: "applmgmt" is "yellow"
    ...    5
    ...    --include-check=^storage
    ...    WARNING: "storage" is "gray"
    ...    6
    ...    --include-check=software-packages
    ...    WARNING: "software-packages" is "orange"
