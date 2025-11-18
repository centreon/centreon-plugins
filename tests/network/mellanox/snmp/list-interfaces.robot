*** Settings ***
Documentation       network::mellanox::snmp::plugin
Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=network::mellanox::snmp::plugin
...         --mode=list-interfaces
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-community=network/mellanox/snmp/mellanox

*** Test Cases ***
List-interfaces
    [Tags]    network    mellanox    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --disco-show

    ${root}=         Ctn Run Command And Return Parsed XML    ${command}
    ${nb_items}=     Get Element Count       ${root}    label


    # First check: are there 5 storage items as expected
    Should Be Equal As Integers    ${nb_items}    55     Number of items do not match for command:${\n}${command}${\n}

    # Get the list of cluster IDs
    @{elem_list}=    Get Elements    ${root}    label
    @{found_items}=    Create List
    FOR    ${item}    IN    @{elemList}
        ${item_name}=    Get Element Attribute    ${item}    name
        Append To List    ${found_items}    ${item_name}
    END
    
    # Here is what is expected
    @{expected_items}=    Create List         Eth1/1/1    Eth1/1/2    Eth1/1/3    Eth1/1/4    Eth1/10    Eth1/11/1    Eth1/11/2    Eth1/11/3    Eth1/11/4    Eth1/12    Eth1/13/1    Eth1/13/2    Eth1/13/3    Eth1/13/4    Eth1/14    Eth1/15    Eth1/16    Eth1/2/1    Eth1/2/2     Eth1/2/3  Eth1/2/4  Eth1/3/1  Eth1/3/2  Eth1/3/3  Eth1/3/4  Eth1/4/1  Eth1/4/2  Eth1/4/3  Eth1/4/4  Eth1/5/1  Eth1/5/2  Eth1/5/3  Eth1/5/4  Eth1/6/1  Eth1/6/2    Eth1/6/3    Eth1/6/4    Eth1/7/1    Eth1/7/2    Eth1/7/3    Eth1/7/4    Eth1/8/1    Eth1/8/2    Eth1/8/3    Eth1/8/4    Eth1/9    Mpo100    Po1    lo    mgmt0    mgmt1    vlan1500    vlan4000    vlan77    vrf-default

    Sort List    ${found_items}
    Sort List    ${expected_items}
    # Compare obtained list with expected list
    Lists Should Be Equal	${found_items}    ${expected_items}

