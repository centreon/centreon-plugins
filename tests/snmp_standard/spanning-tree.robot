*** Settings ***
Documentation       snmp_standard
Resource            ${CURDIR}${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --mode=spanning-tree
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}

*** Test Cases ***
Mellanox-Spanning-tree ${tc}
    [Tags]    network    mellanox    snmp    snmp_standard
    ${command}    Catenate
    ...    ${CMD}
    ...    --plugin=network::mellanox::snmp::plugin
    ...    --snmp-community=snmp_standard/network-mellanox
    ...    --filter-port='Eth1/1/1'
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:      tc    extra_options          expected_result    --
            ...     1    ${EMPTY}               OK: Port 'Eth1/1/1' spanning tree state is 'forwarding' [op status: 'up'] [admin status: 'up'] [index: '89']
            ...     2    --warning-status=1     WARNING: Port 'Eth1/1/1' spanning tree state is 'forwarding' [op status: 'up'] [admin status: 'up'] [index: '89']
            ...     3    --critical-status=1    CRITICAL: Port 'Eth1/1/1' spanning tree state is 'forwarding' [op status: 'up'] [admin status: 'up'] [index: '89']
