*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json

${CMD}              ${CENTREON_PLUGINS} --plugin=apps::vmware::vsphere8::vm::plugin
...                 --password=C3POR2P2
...                 --username=obi-wan
...                 --mode=discovery
...                 --hostname=127.0.0.1
...                 --proto=http
...                 --port=3000


*** Test Cases ***
Discovery ${tc}
    [Tags]    apps    api    vmware    vsphere8    vm    discovery
    ${command}    Catenate    ${CMD} ${extra_options}

    Ctn Run Command Without Connector And Check Result As Regexp    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    "discovered_items":3
    ...    2
    ...    --filter-power-states=POWERED_ON
    ...    "discovered_items":2
    ...    3
    ...    --filter-power-states=POWERED_OFF
    ...    "discovered_items":1
    ...    4
    ...    --filter-folders=My_Dir
    ...    "discovered_items":1
    ...    5
    ...    --filter-power-states=POWERED_OFF --no-tags
    ...    \\{"clean_hostname":"web-server-01",[^}]*"ip_address":"",[^}]*"power_state":"POWERED_OFF","vm_hostname":"","vm_name":"web-server-01"
    ...    6
    ...    --filter-power-states=POWERED_ON --no-tags
    ...    \\{"clean_hostname":"172.16.2.1",[^}]*"ip_address":"172.16.2.1",[^}]*"vm_hostname":"web-server-01","vm_name":"db-server-01"
    ...    7
    ...    --no-identity --no-tags
    ...    ^(?!.*"clean_hostname":"").*\\{"clean_hostname":"db-server-01",[^}]*"ip_address":"",[^}]*"vm_hostname":"","vm_name":"db-server-01"
