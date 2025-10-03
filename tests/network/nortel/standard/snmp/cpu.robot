*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource
Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::nortel::standard::snmp::plugin


*** Test Cases ***
cpu-4950gts-pwr ${tc}
    [Tags]    network    snmp
    [Documentation]    Ethernet Routing Switch 4950GTS-PWR+
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=cpu
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/nortel/standard/snmp/4950gts-pwr
    ...    --filter-counters='${filter}'
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc      filter   extra_options          expected_result    --
            ...      1.0     .*       ${EMPTY}               OK: CPU '3.10.0' usage 46.00 % (1min), 34.00 % (10min), 23.00 % (1h) | '3.10.0#cpu.utilization.1m.percentage'=46.00%;;;0;100 '3.10.0#cpu.utilization.10m.percentage'=34.00%;;;0;100 '3.10.0#cpu.utilization.1h.percentage'=23.00%;;;0;100
            ...      2.0     ^1m$     ${EMPTY}               OK: CPU '3.10.0' usage 46.00 % (1min) | '3.10.0#cpu.utilization.1m.percentage'=46.00%;;;0;100
            ...      2.1     ^1m$     --warning-1m=0:0       WARNING: CPU '3.10.0' usage 46.00 % (1min) | '3.10.0#cpu.utilization.1m.percentage'=46.00%;0:0;;0;100
            ...      2.2     ^1m$     --critical-1m=0:0      CRITICAL: CPU '3.10.0' usage 46.00 % (1min) | '3.10.0#cpu.utilization.1m.percentage'=46.00%;;0:0;0;100
            ...      3.0     ^5m$     ${EMPTY}               OK: CPU '3.10.0' usage
            ...      4.0     ^10m$    ${EMPTY}               OK: CPU '3.10.0' usage 34.00 % (10min) | '3.10.0#cpu.utilization.10m.percentage'=34.00%;;;0;100
            ...      4.1     ^10m$    --warning-10m=0:0      WARNING: CPU '3.10.0' usage 34.00 % (10min) | '3.10.0#cpu.utilization.10m.percentage'=34.00%;0:0;;0;100
            ...      4.2     ^10m$    --critical-10m=0:0     CRITICAL: CPU '3.10.0' usage 34.00 % (10min) | '3.10.0#cpu.utilization.10m.percentage'=34.00%;;0:0;0;100
            ...      5.0     ^1h$     ${EMPTY}               OK: CPU '3.10.0' usage 23.00 % (1h) | '3.10.0#cpu.utilization.1h.percentage'=23.00%;;;0;100
            ...      5.1     ^1h$     --warning-1h=0:0       WARNING: CPU '3.10.0' usage 23.00 % (1h) | '3.10.0#cpu.utilization.1h.percentage'=23.00%;0:0;;0;100
            ...      5.2     ^1h$     --critical-1h=0:0      CRITICAL: CPU '3.10.0' usage 23.00 % (1h) | '3.10.0#cpu.utilization.1h.percentage'=23.00%;;0:0;0;100

cpu-5520-24t ${tc}
    [Tags]    network    snmp
    [Documentation]    Extreme Networks 5520-24T
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=cpu
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/nortel/standard/snmp/5520-24t
    ...    --filter-counters='${filter}'
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc      filter           extra_options                  expected_result    --
            ...      1.0     .*               ${EMPTY}                       OK: CPU 'slot_1' usage 16.00 % (5min) | 'slot_1#cpu.utilization.5m.percentage'=16.00%;;;0;100
            ...      2.0     ^1m$             ${EMPTY}                       OK: CPU 'slot_1' usage
            ...      3.0     ^5m$             ${EMPTY}                       OK: CPU 'slot_1' usage 16.00 % (5min) | 'slot_1#cpu.utilization.5m.percentage'=16.00%;;;0;100
            ...      3.1     ^5m$             --warning-5m=0:0               WARNING: CPU 'slot_1' usage 16.00 % (5min) | 'slot_1#cpu.utilization.5m.percentage'=16.00%;0:0;;0;100
            ...      3.2     ^5m$             --critical-5m=0:0              CRITICAL: CPU 'slot_1' usage 16.00 % (5min) | 'slot_1#cpu.utilization.5m.percentage'=16.00%;;0:0;0;100
            ...      4.0     ^10m$            ${EMPTY}                       OK: CPU 'slot_1' usage
            ...      5.0     ^1h$             ${EMPTY}                       OK: CPU 'slot_1' usage

cpu-7520-48y-8c ${tc}
    [Tags]    network    snmp
    [Documentation]    Extreme Networks 7520-48Y-8C
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=cpu
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/nortel/standard/snmp/7520-48y-8c
    ...    --filter-counters='${filter}'
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc      filter           extra_options                  expected_result    --
            ...      1.0     .*               ${EMPTY}                       OK: CPU 'slot_1' usage 5.00 % (5min) | 'slot_1#cpu.utilization.5m.percentage'=5.00%;;;0;100
            ...      2.0     ^1m$             ${EMPTY}                       OK: CPU 'slot_1' usage
            ...      3.0     ^5m$             ${EMPTY}                       OK: CPU 'slot_1' usage 5.00 % (5min) | 'slot_1#cpu.utilization.5m.percentage'=5.00%;;;0;100
            ...      3.1     ^5m$             --warning-5m=0:0               WARNING: CPU 'slot_1' usage 5.00 % (5min) | 'slot_1#cpu.utilization.5m.percentage'=5.00%;0:0;;0;100
            ...      3.2     ^5m$             --critical-5m=0:0              CRITICAL: CPU 'slot_1' usage 5.00 % (5min) | 'slot_1#cpu.utilization.5m.percentage'=5.00%;;0:0;0;100
            ...      4.0     ^10m$            ${EMPTY}                       OK: CPU 'slot_1' usage
            ...      5.0     ^1h$             ${EMPTY}                       OK: CPU 'slot_1' usage


cpu-7520-48ye-8ce ${tc}
    [Tags]    network    snmp
    [Documentation]    Extreme Networks 7520-48YE-8CE
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=cpu
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/nortel/standard/snmp/7520-48ye-8ce
    ...    --filter-counters='${filter}'
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc      filter           extra_options                  expected_result    --
            ...      1.0     .*               ${EMPTY}                       OK: CPU 'slot_1' usage 6.00 % (5min) | 'slot_1#cpu.utilization.5m.percentage'=6.00%;;;0;100
            ...      2.0     ^1m$             ${EMPTY}                       OK: CPU 'slot_1' usage
            ...      3.0     ^5m$             ${EMPTY}                       OK: CPU 'slot_1' usage 6.00 % (5min) | 'slot_1#cpu.utilization.5m.percentage'=6.00%;;;0;100
            ...      3.1     ^5m$             --warning-5m=0:0               WARNING: CPU 'slot_1' usage 6.00 % (5min) | 'slot_1#cpu.utilization.5m.percentage'=6.00%;0:0;;0;100
            ...      3.2     ^5m$             --critical-5m=0:0              CRITICAL: CPU 'slot_1' usage 6.00 % (5min) | 'slot_1#cpu.utilization.5m.percentage'=6.00%;;0:0;0;100
            ...      4.0     ^10m$            ${EMPTY}                       OK: CPU 'slot_1' usage
            ...      5.0     ^1h$             ${EMPTY}                       OK: CPU 'slot_1' usage
