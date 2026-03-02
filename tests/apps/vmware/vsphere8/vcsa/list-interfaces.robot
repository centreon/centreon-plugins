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
List-Interfaces ${tc}
    [Tags]    apps    vmware    vcsa
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
    ...    --disco-format
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <element>name</element> <element>mac</element> <element>ipv4_address</element> <element>ipv4_mode</element> <element>status</element> </data>
    ...    2
    ...    --disco-show
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <label ipv4_address="172.16.12.2" ipv4_mode="STATIC" mac="00:0c:29:44:12:58" name="nic0" status="up"/> <label ipv4_address="172.16.12.3" ipv4_mode="STATIC" mac="00:0c:29:44:12:32" name="nic1" status="down"/> </data>
