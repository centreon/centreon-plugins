*** Settings ***
Documentation       Network Teldat SNMP plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}                          ${CENTREON_PLUGINS} --plugin=network::teldat::snmp::plugin


*** Test Cases ***
CPU ${tc}
    [Tags]    network    teldat    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=cpu
    ...    --hostname=127.0.0.1
    ...    --snmp-version=2c
    ...    --snmp-port=2024
    ...    --snmp-community=network/teldat/snmp/teldat
    ...    --warning-cpu-utilization-5s=${warningcpuutilization5s}
    ...    --critical-cpu-utilization-5s=${criticalcpuutilization5s}
    ...    --warning-cpu-utilization-1m=${warningcpuutilization1m}
    ...    --critical-cpu-utilization-1m=${criticalcpuutilization1m}
    ...    --warning-cpu-utilization-5m=${warningcpuutilization5m}
    ...    --critical-cpu-utilization-5m=${criticalcpuutilization5m}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}


    Examples:         tc  warningcpuutilization5s  criticalcpuutilization5s  warningcpuutilization1m  criticalcpuutilization1m  warningcpuutilization5m  criticalcpuutilization5m  expected_result    --
            ...       1   ${EMPTY}                 ${EMPTY}                  ${EMPTY}                 ${EMPTY}                  ${EMPTY}                 ${EMPTY}                  OK: cpu average usage: 1.00 % (5s), 1.00 % (1m), 1.00 % (5m) | 'cpu.utilization.5s.percentage'=1.00%;;;0;100 'cpu.utilization.1m.percentage'=1.00%;;;0;100 'cpu.utilization.15m.percentage'=1.00%;;;0;100
            ...       2   0.5                      ${EMPTY}                  ${EMPTY}                 ${EMPTY}                  ${EMPTY}                 ${EMPTY}                  WARNING: cpu average usage: 1.00 % (5s) | 'cpu.utilization.5s.percentage'=1.00%;0:0.5;;0;100 'cpu.utilization.1m.percentage'=1.00%;;;0;100 'cpu.utilization.15m.percentage'=1.00%;;;0;100
            ...       3   ${EMPTY}                 0.5                       ${EMPTY}                 ${EMPTY}                  ${EMPTY}                 ${EMPTY}                  CRITICAL: cpu average usage: 1.00 % (5s) | 'cpu.utilization.5s.percentage'=1.00%;;0:0.5;0;100 'cpu.utilization.1m.percentage'=1.00%;;;0;100 'cpu.utilization.15m.percentage'=1.00%;;;0;100
            ...       4   ${EMPTY}                 ${EMPTY}                  0.5                      ${EMPTY}                  ${EMPTY}                 ${EMPTY}                  WARNING: cpu average usage: 1.00 % (1m) | 'cpu.utilization.5s.percentage'=1.00%;;;0;100 'cpu.utilization.1m.percentage'=1.00%;0:0.5;;0;100 'cpu.utilization.15m.percentage'=1.00%;;;0;100
            ...       5   ${EMPTY}                 ${EMPTY}                  ${EMPTY}                 0.5                       ${EMPTY}                 ${EMPTY}                  CRITICAL: cpu average usage: 1.00 % (1m) | 'cpu.utilization.5s.percentage'=1.00%;;;0;100 'cpu.utilization.1m.percentage'=1.00%;;0:0.5;0;100 'cpu.utilization.15m.percentage'=1.00%;;;0;100
            ...       6   ${EMPTY}                 ${EMPTY}                  ${EMPTY}                 ${EMPTY}                  0.5                      ${EMPTY}                  WARNING: cpu average usage: 1.00 % (5m) | 'cpu.utilization.5s.percentage'=1.00%;;;0;100 'cpu.utilization.1m.percentage'=1.00%;;;0;100 'cpu.utilization.15m.percentage'=1.00%;0:0.5;;0;100
            ...       7   ${EMPTY}                 ${EMPTY}                  ${EMPTY}                 ${EMPTY}                  ${EMPTY}                 0.5                       CRITICAL: cpu average usage: 1.00 % (5m) | 'cpu.utilization.5s.percentage'=1.00%;;;0;100 'cpu.utilization.1m.percentage'=1.00%;;;0;100 'cpu.utilization.15m.percentage'=1.00%;;0:0.5;0;100
