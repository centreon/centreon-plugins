*** Settings ***
Documentation       snmp_standard
Resource            ${CURDIR}${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --mode=cpu
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}

*** Test Cases ***
Mellanox-Cpu ${tc}
    [Tags]    network    mellanox    snmp    snmp_standard
    ${command}    Catenate
    ...    ${CMD}
    ...    --plugin=network::mellanox::snmp::plugin
    ...    --snmp-community=snmp_standard/network-mellanox
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:      tc    extra_options           expected_result    --
            ...     1    ${EMPTY}                OK: 4 CPU(s) average usage is 8.00 % | 'total_cpu_avg'=8.00%;;;0;100 'cpu_0'=8.00%;;;0;100 'cpu_1'=8.00%;;;0;100 'cpu_2'=8.00%;;;0;100 'cpu_3'=8.00%;;;0;100
            ...     2    --warning-average=1     WARNING: 4 CPU(s) average usage is 8.00 % | 'total_cpu_avg'=8.00%;0:1;;0;100 'cpu_0'=8.00%;;;0;100 'cpu_1'=8.00%;;;0;100 'cpu_2'=8.00%;;;0;100 'cpu_3'=8.00%;;;0;100
            ...     3    --critical-average=1    CRITICAL: 4 CPU(s) average usage is 8.00 % | 'total_cpu_avg'=8.00%;;0:1;0;100 'cpu_0'=8.00%;;;0;100 'cpu_1'=8.00%;;;0;100 'cpu_2'=8.00%;;;0;100 'cpu_3'=8.00%;;;0;100
            ...     4    --warning-core=1        WARNING: CPU '0' usage : 8.00 % - CPU '1' usage : 8.00 % - CPU '2' usage : 8.00 % - CPU '3' usage : 8.00 % | 'total_cpu_avg'=8.00%;;;0;100 'cpu_0'=8.00%;0:1;;0;100 'cpu_1'=8.00%;0:1;;0;100 'cpu_2'=8.00%;0:1;;0;100 'cpu_3'=8.00%;0:1;;0;100
            ...     5    --critical-core=1       CRITICAL: CPU '0' usage : 8.00 % - CPU '1' usage : 8.00 % - CPU '2' usage : 8.00 % - CPU '3' usage : 8.00 % | 'total_cpu_avg'=8.00%;;;0;100 'cpu_0'=8.00%;;0:1;0;100 'cpu_1'=8.00%;;0:1;0;100 'cpu_2'=8.00%;;0:1;0;100 'cpu_3'=8.00%;;0:1;0;100
