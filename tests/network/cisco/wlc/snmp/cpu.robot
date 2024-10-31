*** Settings ***
Documentation       Check CPU usage (AIRESPACE-SWITCHING-MIB)

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::cisco::wlc::snmp::plugin


*** Test Cases ***
cpu ${tc}
    [Tags]    network    wlc    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=cpu
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/cisco/wlc/snmp/slim_cisco_wlc
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                    expected_result    --
            ...      1     --warning-cpu-utilization                        OK: cpu usage is: 2.00% | 'cpu.utilization.percentage'=2.00%;;;0;100
            ...      2     --critical-cpu-utilization                       OK: cpu usage is: 2.00% | 'cpu.utilization.percentage'=2.00%;;;0;100
            ...      3     --verbose                                        OK: cpu usage is: 2.00% | 'cpu.utilization.percentage'=2.00%;;;0;100