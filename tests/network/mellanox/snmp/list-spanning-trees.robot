*** Settings ***
Documentation       network::mellanox::snmp::plugin
Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=network::mellanox::snmp::plugin
...         --mode=list-spanning-trees
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-community=network/mellanox/snmp/mellanox

*** Test Cases ***
List-spanning-trees
    [Tags]    network    mellanox    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --disco-show

    ${root}=         Ctn Run Command And Return Parsed XML    ${command}
    ${nb_items}=     Get Element Count       ${root}    label


    # First check: are there 5 storage items as expected
    Should Be Equal As Integers    ${nb_items}    18     Number of items do not match for command:${\n}${command}${\n}

    # Get the list of cluster IDs
    @{elem_list}=    Get Elements    ${root}    label
    @{found_items}=    Create List
    FOR    ${item}    IN    @{elemList}
        ${item_name}=    Get Element Attribute    ${item}    port
        Append To List    ${found_items}    ${item_name}
    END
    
    # Here is what is expected
    @{expected_items}=    Create List         Eth1/1/1    Eth1/1/2    Eth1/1/3    Eth1/1/4    Eth1/13/1    Eth1/13/2    Eth1/13/3    Eth1/13/4    Eth1/2/1    Eth1/2/2    Eth1/2/3    Eth1/2/4    Eth1/4/1    Eth1/4/2    Eth1/5/1    Eth1/5/2    Mpo100    Po1

    Sort List    ${found_items}
    Sort List    ${expected_items}
    # Compare obtained list with expected list
    Lists Should Be Equal	${found_items}    ${expected_items}    Lists do not match for command${\n}${command}${\n}

