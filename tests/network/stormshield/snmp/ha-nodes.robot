*** Settings ***
Documentation       network::stormshield::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=network::stormshield::snmp::plugin
...         --mode=ha-nodes
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-version=${SNMPVERSION}


*** Test Cases ***
Ha-nodes SN910 ${tc}
    [Tags]    network    stormshield    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --snmp-community=network/stormshield/snmp/sn910
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: Dead nodes: 0/2 (0.00%) - All HA nodes are OK | 'ha.dead_nodes.count'=0;;;0;2 'fw_1#ha.node.health.percentage'=100%;;;0;100 'fw_2#ha.node.health.percentage'=33%;;;0;100
    ...    2
    ...    --include-node=fw_1
    ...    OK: Dead nodes: 0/2 (0.00%) - Node 'fw_1' state is 'online' [role: Master], health: 100% | 'ha.dead_nodes.count'=0;;;0;2 'fw_1#ha.node.health.percentage'=100%;;;0;100
    ...    3
    ...    --exclude-node=fw_1
    ...    OK: Dead nodes: 0/2 (0.00%) - Node 'fw_2' state is 'online' [role: Master], health: 33% | 'ha.dead_nodes.count'=0;;;0;2 'fw_2#ha.node.health.percentage'=33%;;;0;100
    ...    4
    ...    --filter-node=fw_2
    ...    OK: Dead nodes: 0/2 (0.00%) - Node 'fw_2' state is 'online' [role: Master], health: 33% | 'ha.dead_nodes.count'=0;;;0;2 'fw_2#ha.node.health.percentage'=33%;;;0;100
    ...    5
    ...    --include-node=nomatch
    ...    UNKNOWN: No nodes found.
    ...    6
    ...    --warning-health=50:
    ...    WARNING: Node 'fw_2' health: 33% | 'ha.dead_nodes.count'=0;;;0;2 'fw_1#ha.node.health.percentage'=100%;50:;;0;100 'fw_2#ha.node.health.percentage'=33%;50:;;0;100
    ...    7
    ...    --critical-health=50:
    ...    CRITICAL: Node 'fw_2' health: 33% | 'ha.dead_nodes.count'=0;;;0;2 'fw_1#ha.node.health.percentage'=100%;;50:;0;100 'fw_2#ha.node.health.percentage'=33%;;50:;0;100
    ...    8
    ...    --warning-dead-nodes=1:
    ...    WARNING: Dead nodes: 0/2 (0.00%) | 'ha.dead_nodes.count'=0;;;0;2 'fw_1#ha.node.health.percentage'=100%;;;0;100 'fw_2#ha.node.health.percentage'=33%;;;0;100
    ...    9
    ...    --percent --critical-dead-nodes=1:
    ...    CRITICAL: Dead nodes: 0/2 (0.00%) | 'ha.dead_nodes.count'=0;;;0;2 'fw_1#ha.node.health.percentage'=100%;;;0;100 'fw_2#ha.node.health.percentage'=33%;;;0;100
    ...    10
    ...    --percent --critical-dead-nodes=0:10
    ...    OK: Dead nodes: 0/2 (0.00%) - All HA nodes are OK | 'ha.dead_nodes.count'=0;;;0;2 'fw_1#ha.node.health.percentage'=100%;;;0;100 'fw_2#ha.node.health.percentage'=33%;;;0;100
    ...    11
    ...    --warning-state='${PERCENT}\\{role\\} eq "Master"'
    ...    WARNING: Node 'fw_1' state is 'online' [role: Master] - Node 'fw_2' state is 'online' [role: Master] | 'ha.dead_nodes.count'=0;;;0;2 'fw_1#ha.node.health.percentage'=100%;;;0;100 'fw_2#ha.node.health.percentage'=33%;;;0;100
    ...    12
    ...    --critical-state='${PERCENT}\\{state\\} eq "online"'
    ...    CRITICAL: Node 'fw_1' state is 'online' [role: Master] - Node 'fw_2' state is 'online' [role: Master] | 'ha.dead_nodes.count'=0;;;0;2 'fw_1#ha.node.health.percentage'=100%;;;0;100 'fw_2#ha.node.health.percentage'=33%;;;0;100
