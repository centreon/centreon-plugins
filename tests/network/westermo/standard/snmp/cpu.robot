*** Settings ***
Documentation       network::westermo::standard::snmp::mode::cpu

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=network::westermo::standard::snmp::plugin
...         --mode=cpu
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-community=network/westermo/standard/snmp/westermo_cpu


*** Test Cases ***
Cpu ${tc}
    [Tags]    network    westermo    snmp
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
    ...    OK: 17.00 % (1m), 7.00 % (5m), 5.00 % (15m) | 'cpu.utilization.1m.percentage'=17.00%;;;0;100 'cpu.utilization.5m.percentage'=7.00%;;;0;100 'cpu.utilization.15m.percentage'=5.00%;;;0;100
    ...    2
    ...    --filter-counters=1
    ...    OK: 17.00 % (1m), 5.00 % (15m) | 'cpu.utilization.1m.percentage'=17.00%;;;0;100 'cpu.utilization.15m.percentage'=5.00%;;;0;100
    ...    3
    ...    --warning-average-15m=1
    ...    WARNING: 5.00 % (15m) | 'cpu.utilization.1m.percentage'=17.00%;;;0;100 'cpu.utilization.5m.percentage'=7.00%;;;0;100 'cpu.utilization.15m.percentage'=5.00%;0:1;;0;100
    ...    4
    ...    --critical-average-15m=1
    ...    CRITICAL: 5.00 % (15m) | 'cpu.utilization.1m.percentage'=17.00%;;;0;100 'cpu.utilization.5m.percentage'=7.00%;;;0;100 'cpu.utilization.15m.percentage'=5.00%;;0:1;0;100
    ...    5
    ...    --warning-average-1m=1
    ...    WARNING: 17.00 % (1m) | 'cpu.utilization.1m.percentage'=17.00%;0:1;;0;100 'cpu.utilization.5m.percentage'=7.00%;;;0;100 'cpu.utilization.15m.percentage'=5.00%;;;0;100
    ...    6
    ...    --critical-average-1m=1
    ...    CRITICAL: 17.00 % (1m) | 'cpu.utilization.1m.percentage'=17.00%;;0:1;0;100 'cpu.utilization.5m.percentage'=7.00%;;;0;100 'cpu.utilization.15m.percentage'=5.00%;;;0;100
    ...    7
    ...    --warning-average-5m=1
    ...    WARNING: 7.00 % (5m) | 'cpu.utilization.1m.percentage'=17.00%;;;0;100 'cpu.utilization.5m.percentage'=7.00%;0:1;;0;100 'cpu.utilization.15m.percentage'=5.00%;;;0;100
    ...    8
    ...    --critical-average-5m=1
    ...    CRITICAL: 7.00 % (5m) | 'cpu.utilization.1m.percentage'=17.00%;;;0;100 'cpu.utilization.5m.percentage'=7.00%;;0:1;0;100 'cpu.utilization.15m.percentage'=5.00%;;;0;100
