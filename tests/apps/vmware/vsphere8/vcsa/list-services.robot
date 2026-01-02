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
...         --mode=services
...         --hostname=${HOSTNAME}
...         --port=${APIPORT}
...         --proto=http
...         --username=1
...         --password=1


*** Test Cases ***
List-Services ${tc}
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
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <element>id</element> <element>state</element> <element>description</element> </data>
    ...    2
    ...    --disco-show --include-id='(observability\\\|vmware-pod)'
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <label description="VMware Observability Service" id="observability" state="STARTED"/> <label description="VMware Pod Service." id="vmware-pod" state="STARTED"/> </data>

