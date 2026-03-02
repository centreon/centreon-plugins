*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json

${CMD}              ${CENTREON_PLUGINS} --plugin=apps::vmware::vsphere8::vcenter::plugin
...                 --mode=list-clusters
...                 --password=C3POR2P2
...                 --username=obi-wan
...                 --hostname=127.0.0.1
...                 --proto=http
...                 --port=3000


*** Test Cases ***
List-Datastores
    [Tags]    apps    api    vmware    vsphere8    vcenter
    ${command}=    Catenate    ${CMD} --http-backend=curl --disco-show

# expected disco-show
# <?xml version="1.0" encoding="utf-8"?>
 #<data>
 #    <label cluster="domain-c18" name="AQU-CLU01" ha_enabled="true" drs_enabled="false"/>
 #</data>

    ${root}=    Ctn Run Command And Return Parsed XML    ${command}
    ${nb_clusters}=    Get Element Count    ${root}    label

    # First check: are there 8 datastores as expected
    Should Be Equal As Integers    ${nb_clusters}    1    Number of clusters do not match

    # Get the list of cluster IDs
    @{elem_list}=    Get Elements    ${root}    label
    @{found_clusters}=    Create List
    FOR    ${item}    IN    @{elemList}
        ${clusters_id}=    Get Element Attribute    ${item}    cluster
        Append To List    ${found_clusters}    ${clusters_id}
    END
    # Here is what is expected
    @{expected_clusters}=    Create List    domain-c18
    # Compare obtained list with expected list
    Lists Should Be Equal    ${found_clusters}    ${expected_clusters}

Disco-format
    ${command}=    Catenate    ${CMD} --disco-format
    ${root}=    Ctn Run Command And Return Parsed XML    ${command}

# expected disco-format
# <?xml version="1.0" encoding="utf-8"?>
# <data>
#    <element>name</element>
#    <element>cluster</element>
#    <element>drs_enabled</element>
#    <element>ha_enabled</element>
# </data>

    # Get the list of cluster IDs
    @{elem_list}=    Get Elements    ${root}    element
    @{found_macros}=    Create List
    FOR    ${item}    IN    @{elemList}
        ${macro_name}=    Get Element Text    ${item}
        Append To List    ${found_macros}    ${macro_name}
    END
    # Here is what is expected
    @{expected_macros}=    Create List    name    cluster    drs_enabled    ha_enabled
    # Compare obtained list with expected list
    Lists Should Be Equal    ${found_macros}    ${expected_macros}
