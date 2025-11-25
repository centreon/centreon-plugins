*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json

${CMD}              ${CENTREON_PLUGINS} --plugin=apps::vmware::vsphere8::vcenter::plugin
...                 --mode=list-datastores
...                 --password=C3POR2P2
...                 --username=obi-wan
...                 --hostname=127.0.0.1
...                 --proto=http
...                 --port=3000


*** Test Cases ***
List-Datastores
    [Tags]    apps    api    vmware    vsphere8    vcenter
    ${command_curl}=    Catenate    ${CMD} --http-backend=curl --disco-show

# <?xml version="1.0" encoding="utf-8"?>
# <data>
#    <label datastore="datastore-14" type="VMFS" name="Datastore - Systeme" free_space="610635087872" capacity="799937658880"/>
#    <label datastore="datastore-25" capacity="341986770944" name="Datastore - ESX02" free_space="340472627200" type="VMFS"/>
#    <label capacity="341986770944" type="VMFS" free_space="340472627200" name="Datastore - ESX03" datastore="datastore-31"/>
#    <label datastore="datastore-38" free_space="5586639912960" name="Datastore - Developpement 15000" type="VMFS" capacity="7794560335872"/>
#    <label datastore="datastore-39" type="VMFS" free_space="5422671986688" name="Datastore - Developpement 7200" capacity="5516885491712"/>
#    <label datastore="datastore-40" free_space="340472627200" name="Datastore - ESX01" type="VMFS" capacity="341986770944"/>
#    <label datastore="datastore-45" capacity="7499818205184" free_space="4376304287744" name="Datastore - Developpement" type="VMFS"/>
#    <label type="VMFS" free_space="615292862464" name="Datastore - Production" capacity="1299764477952" datastore="datastore-46"/>
# </data>

    ${root}=    Ctn Run Command And Return Parsed XML    ${command_curl}
    ${nb_ds}=    Get Element Count    ${root}    label

    # First check: are there 8 datastores as expected
    Should Be Equal As Integers    ${nb_ds}    8    Number of datastores do not match

    # Get the list of datastore IDs
    @{elem_list}=    Get Elements    ${root}    label
    @{found_ds}=    Create List
    FOR    ${item}    IN    @{elemList}
        ${ds_id}=    Get Element Attribute    ${item}    datastore
        Append To List    ${found_ds}    ${ds_id}
    END
    # Here is what is expected
    @{expected_ds}=    Create List
    ...    datastore-14
    ...    datastore-25
    ...    datastore-31
    ...    datastore-38
    ...    datastore-39
    ...    datastore-40
    ...    datastore-45
    ...    datastore-46
    # Compare obtained list with expected list
    Lists Should Be Equal    ${found_ds}    ${expected_ds}
