*** Settings ***
Documentation       network::stormshield::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=network::stormshield::snmp::plugin
...         --mode=memory-detailed
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-version=${SNMPVERSION}


*** Test Cases ***
Connections SN910 ${tc}
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
    ...    OK: Memory usage total: 15.00 %, protected host: 0.00 %, fragmented: 0.00 %, icmp: 7.00 %, Data Tracking: 0.00%, dynamic: 1.00 %, EtherState: 0%, Socket: 0%, User: 7% | 'memory.usage.percentage'=15.00%;;;0;100 'memory.protected_host.percentage'=0.00%;;;0;100 'memory.fragmented.percentage'=0.00%;;;0;100 'memory.icmp.percentage'=7.00%;;;0;100 'memory.data_tracking.percentage'=0.00%;;;0;100 'memory.dynamic.percentage'=1.00%;;;0;100 'memory.ether_state.percentage'=0.00%;;;0;100 'memory.socket.percentage'=0%;;;0;100 'memory.user.percentage'=7%;;;0;100
    ...    2
    ...    --warning-total=4
    ...    WARNING: Memory usage total: 15.00 % | 'memory.usage.percentage'=15.00%;0:4;;0;100 'memory.protected_host.percentage'=0.00%;;;0;100 'memory.fragmented.percentage'=0.00%;;;0;100 'memory.icmp.percentage'=7.00%;;;0;100 'memory.data_tracking.percentage'=0.00%;;;0;100 'memory.dynamic.percentage'=1.00%;;;0;100 'memory.ether_state.percentage'=0.00%;;;0;100 'memory.socket.percentage'=0%;;;0;100 'memory.user.percentage'=7%;;;0;100
    ...    3
    ...    --critical-dyn=4:
    ...    CRITICAL: Memory usage dynamic: 1.00 % | 'memory.usage.percentage'=15.00%;;;0;100 'memory.protected_host.percentage'=0.00%;;;0;100 'memory.fragmented.percentage'=0.00%;;;0;100 'memory.icmp.percentage'=7.00%;;;0;100 'memory.data_tracking.percentage'=0.00%;;;0;100 'memory.dynamic.percentage'=1.00%;;4:;0;100 'memory.ether_state.percentage'=0.00%;;;0;100 'memory.socket.percentage'=0%;;;0;100 'memory.user.percentage'=7%;;;0;100
