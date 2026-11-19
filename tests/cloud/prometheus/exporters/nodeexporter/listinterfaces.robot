*** Settings ***
Documentation     Prometheus Node Exporter plugin

Resource          ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup       Start Mockoon    ${MOCKOON_JSON}
Suite Teardown    Stop Mockoon
Test Timeout      120s


*** Variables ***
${MOCKOON_JSON}    ${CURDIR}${/}mockoon.json

${BASE_URL}        http://${HOSTNAME}:${APIPORT}
${CMD}             ${CENTREON_PLUGINS} --plugin=cloud::prometheus::exporters::nodeexporter::plugin --mode=interfaces --hostname=${HOSTNAME} --port=${APIPORT}


*** Test Cases ***
List-Interfaces
    [Tags]    cloud    prometheus
    ${command}    Catenate
    ...    ${CMD}
    ...    --disco-show

    ${root}=    Ctn Run Command And Return Parsed XML    ${command}
    ${nb_items}=    Get Element Count    ${root}    label

    # First check: are there 5 storage items as expected
    Should Be Equal As Integers    ${nb_items}    11    Number of items do not match for command:${\n}${command}${\n}

    # Get the list of cluster IDs
    @{elem_list}=    Get Elements    ${root}    label
    @{found_items}=    Create List
    FOR    ${item}    IN    @{elemList}
        ${item_name}=    Get Element Attribute    ${item}    name
        Append To List    ${found_items}    ${item_name}
    END

    # Here is what is expected
    @{expected_items}=    Create List
    ...    IF_VIRT
    ...    IF_VIRT2
    ...    IF_VIRT3
    ...    dif0
    ...    eth0
    ...    eth1
    ...    eth2
    ...    eth3
    ...    eth4
    ...    NET_PROD
    ...    lo
    Sort List    ${found_items}
    Sort List    ${expected_items}
    # Compare obtained list with expected list
    Lists Should Be Equal    ${found_items}    ${expected_items}

List-Interfaces-Without-Adminstate
    [Tags]    cloud    prometheus
    ${command}    Catenate
    ...    ${CMD}
    ...    --url-path=/legacy/api/v1
    ...    --disco-show

    Ctn Run Command Without Connector And Check Result As Strings
    ...    ${command}
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <label admstatus="up" instance="127.0.0.1:9101" name="eth0" opstatus="up"/> <label admstatus="down" instance="127.0.0.1:9101" name="eth1" opstatus="down"/> <label admstatus="up" instance="127.0.0.1:9101" name="eth2" opstatus="down"/> <label admstatus="unknown" instance="127.0.0.1:9101" name="eth3" opstatus="up"/> <label admstatus="up" instance="127.0.0.1:9101" name="lo" opstatus="unknown"/> </data>
