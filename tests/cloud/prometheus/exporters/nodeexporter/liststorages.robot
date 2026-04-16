*** Settings ***
Documentation       Prometheus Node Exporter plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}         ${CURDIR}${/}mockoon.json

${BASE_URL}             http://${HOSTNAME}:${APIPORT}
${CMD}                  ${CENTREON_PLUGINS} --plugin=cloud::prometheus::exporters::nodeexporter::plugin --mode=storage --hostname=${HOSTNAME} --port=${APIPORT} --http-backend=curl



*** Test Cases ***
List-Storage
    [Tags]    cloud    prometheus
    ${command}    Catenate
    ...    ${CMD}
    ...    --disco-show

    ${root}=            Ctn Run Command And Return Parsed XML    ${command}
    ${nb_storages}=     Get Element Count       ${root}    label

    # Expected XML output:
    #<?xml version="1.0" encoding="utf-8"?>
    #<data>
    #  <label fstype="ext4" instance="127.0.0.1:9101" size="20940668928" name="/data"/>
    #  <label instance="127.0.0.1:9101" size="20940668928" name="/var/log/journal" fstype="ext4"/>
    #  <label instance="127.0.0.1:9101" name="/" size="10296250368" fstype="ext4"/>
    #  <label fstype="ext4" instance="127.0.0.1:9101" size="10296250368" name="/data/overlay-etc/primary/lower"/>
    #  <label fstype="vfat" name="/efi" size="17377280" instance="127.0.0.1:9101"/>
    #</data>

    # First check: are there 5 storage items as expected
    Should Be Equal As Integers    ${nb_storages}    5     Number of clusters do not match for command:${\n}${command}${\n}

    # Get the list of cluster IDs
    @{elem_list}=    Get Elements    ${root}    label
    @{found_storages}=    Create List
    FOR    ${item}    IN    @{elemList}
        ${storage_name}=    Get Element Attribute    ${item}    name
        Append To List    ${found_storages}    ${storage_name}
    END
    # Here is what is expected
    @{expected_storages}=    Create List    /data    /var/log/journal    /    /data/overlay-etc/primary/lower    /efi
    # Compare obtained list with expected list
    Lists Should Be Equal	${found_storages}    ${expected_storages}


