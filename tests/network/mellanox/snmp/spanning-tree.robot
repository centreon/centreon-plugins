*** Settings ***
Documentation       network::mellanox::snmp::plugin
Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=network::mellanox::snmp::plugin
...         --mode=spanning-tree
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-community=network/mellanox/snmp/mellanox

*** Test Cases ***
Spanning-tree ${tc}
    [Tags]    network    mellanox    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --filter-port='Eth1/1/1'
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:      tc    extra_options          expected_result    --
            ...     1    ${EMPTY}               OK: Port 'Eth1/1/1' spanning tree state is 'forwarding' [op status: 'up'] [admin status: 'up'] [index: '89']
            ...     2    --warning-status=1     WARNING: Port 'Eth1/1/1' spanning tree state is 'forwarding' [op status: 'up'] [admin status: 'up'] [index: '89']
            ...     3    --critical-status=1    CRITICAL: Port 'Eth1/1/1' spanning tree state is 'forwarding' [op status: 'up'] [admin status: 'up'] [index: '89']
