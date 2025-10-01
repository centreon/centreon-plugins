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
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc      extra_options                                          expected_result    --
            ...      1.0     --filter-counters='.*'                          OK: CPU '3.10.0' usage 46.00 % (1min), 34.00 % (10min), 23.00 % (1h) | '3.10.0#cpu.utilization.1m.percentage'=46.00%;;;0;100 '3.10.0#cpu.utilization.10m.percentage'=34.00%;;;0;100 '3.10.0#cpu.utilization.1h.percentage'=23.00%;;;0;100
            ...      2.0     --filter-counters='^1m$'                        OK: CPU '3.10.0' usage 46.00 % (1min) | '3.10.0#cpu.utilization.1m.percentage'=46.00%;;;0;100
            ...      2.1     --filter-counters='^1m$' --warning-1m=0:0       WARNING: CPU '3.10.0' usage 46.00 % (1min) | '3.10.0#cpu.utilization.1m.percentage'=46.00%;0:0;;0;100
            ...      2.2     --filter-counters='^1m$' --critical-1m=0:0      CRITICAL: CPU '3.10.0' usage 46.00 % (1min) | '3.10.0#cpu.utilization.1m.percentage'=46.00%;;0:0;0;100
            ...      3.0     --filter-counters='^5m$'                        OK: CPU '3.10.0' usage
            ...      4.0     --filter-counters='^10m$'                       OK: CPU '3.10.0' usage 34.00 % (10min) | '3.10.0#cpu.utilization.10m.percentage'=34.00%;;;0;100
            ...      4.1     --filter-counters='^10m$' --warning-10m=0:0     WARNING: CPU '3.10.0' usage 34.00 % (10min) | '3.10.0#cpu.utilization.10m.percentage'=34.00%;0:0;;0;100
            ...      4.2     --filter-counters='^10m$' --critical-10m=0:0    CRITICAL: CPU '3.10.0' usage 34.00 % (10min) | '3.10.0#cpu.utilization.10m.percentage'=34.00%;;0:0;0;100
            ...      5.0     --filter-counters='^1h$'                        OK: CPU '3.10.0' usage 23.00 % (1h) | '3.10.0#cpu.utilization.1h.percentage'=23.00%;;;0;100
            ...      5.1     --filter-counters='^1h$' --warning-1h=0:0       WARNING: CPU '3.10.0' usage 23.00 % (1h) | '3.10.0#cpu.utilization.1h.percentage'=23.00%;0:0;;0;100
            ...      5.2     --filter-counters='^1h$' --critical-1h=0:0      CRITICAL: CPU '3.10.0' usage 23.00 % (1h) | '3.10.0#cpu.utilization.1h.percentage'=23.00%;;0:0;0;100
