*** Settings ***
Documentation       network::stormshield::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=network::stormshield::snmp::plugin
...         --mode=ha-cluster
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-version=${SNMPVERSION}
...         --snmp-community=network/stormshield/snmp/sn910


*** Test Cases ***
Ha-cluster ${tc}
    [Tags]    network    stormshield    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    WARNING: Configuration Synced: False | 'ha.dead_nodes.count'=0;0:1;0:2;0;2 'ha.faulty_links.count'=0;0:1;0:2;0;2 'ha.active_firewalls.count'=1;;1:1;0;2
    ...    2
    ...    --warning-active-firewall=0:0 --warning-sync-status=0
    ...    WARNING: Active Firewalls: 1/2 | 'ha.dead_nodes.count'=0;0:1;0:2;0;2 'ha.faulty_links.count'=0;0:1;0:2;0;2 'ha.active_firewalls.count'=1;0:0;1:1;0;2
    ...    3
    ...    --critical-active-firewall=0:0 --warning-sync-status=0
    ...    CRITICAL: Active Firewalls: 1/2 | 'ha.dead_nodes.count'=0;0:1;0:2;0;2 'ha.faulty_links.count'=0;0:1;0:2;0;2 'ha.active_firewalls.count'=1;;0:0;0;2
    ...    4
    ...    --warning-dead-nodes=1: --warning-sync-status=0
    ...    WARNING: Dead Nodes: 0/2 (0%) | 'ha.dead_nodes.count'=0;0:;0:2;0;2 'ha.faulty_links.count'=0;0:1;0:2;0;2 'ha.active_firewalls.count'=1;;1:1;0;2
    ...    5
    ...    --critical-dead-nodes=1: --warning-sync-status=0
    ...    CRITICAL: Dead Nodes: 0/2 (0%) | 'ha.dead_nodes.count'=0;0:1;0:;0;2 'ha.faulty_links.count'=0;0:1;0:2;0;2 'ha.active_firewalls.count'=1;;1:1;0;2
    ...    6
    ...    --warning-faulty-links=1: --warning-sync-status=0
    ...    WARNING: Faulty Links: 0/2 (0%) | 'ha.dead_nodes.count'=0;0:1;0:2;0;2 'ha.faulty_links.count'=0;0:;0:2;0;2 'ha.active_firewalls.count'=1;;1:1;0;2
    ...    7
    ...    --critical-faulty-links=1: --warning-sync-status=0
    ...    CRITICAL: Faulty Links: 0/2 (0%) | 'ha.dead_nodes.count'=0;0:1;0:2;0;2 'ha.faulty_links.count'=0;0:1;0:;0;2 'ha.active_firewalls.count'=1;;1:1;0;2
    ...    8
    ...    --warning-sync-status='${PERCENT}\\{sync_status\\} eq "False"'
    ...    WARNING: Configuration Synced: False | 'ha.dead_nodes.count'=0;0:1;0:2;0;2 'ha.faulty_links.count'=0;0:1;0:2;0;2 'ha.active_firewalls.count'=1;;1:1;0;2
    ...    9
    ...    --critical-sync-status='${PERCENT}\\{sync_status\\} eq "False"'
    ...    CRITICAL: Configuration Synced: False | 'ha.dead_nodes.count'=0;0:1;0:2;0;2 'ha.faulty_links.count'=0;0:1;0:2;0;2 'ha.active_firewalls.count'=1;;1:1;0;2
