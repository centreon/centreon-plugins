*** Settings ***
Documentation       Network citrix netscaler health

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::cisco::standard::snmp::plugin


*** Test Cases ***
cpu ${tc}
    [Tags]    network    citrix    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=cpu
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/cisco/standard/snmp/cisco
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                 expected_result    --
            ...      1     --verbose                                                                     OK: 1 CPU(s) average usage is 60.00 % (5s) 57.00 % (1m) 48.00 % (5m) - CPU '1' usage 60.00 % (5s) 57.00 % (1m) 48.00 % (5m) | 'total_cpu_5s_avg'=60.00%;;;0;100 'total_cpu_1m_avg'=57.00%;;;0;100 'total_cpu_5m_avg'=48.00%;;;0;100 'cpu_5s'=60.00%;;;0;100 'cpu_1m'=57.00%;;;0;100 'cpu_5m'=48.00%;;;0;100 CPU '1' usage 60.00 % (5s) 57.00 % (1m) 48.00 % (5m)
            ...      2     --check-order='process,old_sys,system_ext'                                    OK: 1 CPU(s) average usage is 60.00 % (5s) 57.00 % (1m) 48.00 % (5m) - CPU '1' usage 60.00 % (5s) 57.00 % (1m) 48.00 % (5m) | 'total_cpu_5s_avg'=60.00%;;;0;100 'total_cpu_1m_avg'=57.00%;;;0;100 'total_cpu_5m_avg'=48.00%;;;0;100 'cpu_5s'=60.00%;;;0;100 'cpu_1m'=57.00%;;;0;100 'cpu_5m'=48.00%;;;0;100  
            ...      3     --warning-average-5s=0:2 --critical-average-5s=0:2                            CRITICAL: 1 CPU(s) average usage is 60.00 % (5s) | 'total_cpu_5s_avg'=60.00%;0:2;0:2;0;100 'total_cpu_1m_avg'=57.00%;;;0;100 'total_cpu_5m_avg'=48.00%;;;0;100 'cpu_5s'=60.00%;;;0;100 'cpu_1m'=57.00%;;;0;100 'cpu_5m'=48.00%;;;0;100
            ...      4     --warning-core-1m=0:1 --critical-core-1m=0:1                                  CRITICAL: CPU '1' usage 57.00 % (1m) | 'total_cpu_5s_avg'=60.00%;;;0;100 'total_cpu_1m_avg'=57.00%;;;0;100 'total_cpu_5m_avg'=48.00%;;;0;100 'cpu_5s'=60.00%;;;0;100 'cpu_1m'=57.00%;0:1;0:1;0;100 'cpu_5m'=48.00%;;;0;100
            ...      5     --warning-average-5s=0:5 --critical-average-5s=0:5                            CRITICAL: 1 CPU(s) average usage is 60.00 % (5s) | 'total_cpu_5s_avg'=60.00%;0:5;0:5;0;100 'total_cpu_1m_avg'=57.00%;;;0;100 'total_cpu_5m_avg'=48.00%;;;0;100 'cpu_5s'=60.00%;;;0;100 'cpu_1m'=57.00%;;;0;100 'cpu_5m'=48.00%;;;0;100
            ...      6     --warning-average-1m=0:2 --critical-average-1m=0:2                            CRITICAL: 1 CPU(s) average usage is 57.00 % (1m) | 'total_cpu_5s_avg'=60.00%;;;0;100 'total_cpu_1m_avg'=57.00%;0:2;0:2;0;100 'total_cpu_5m_avg'=48.00%;;;0;100 'cpu_5s'=60.00%;;;0;100 'cpu_1m'=57.00%;;;0;100 'cpu_5m'=48.00%;;;0;100
            ...      7     --warning-average-5m=0:2 --critical-average-5m=0:0                            CRITICAL: 1 CPU(s) average usage is 48.00 % (5m) | 'total_cpu_5s_avg'=60.00%;;;0;100 'total_cpu_1m_avg'=57.00%;;;0;100 'total_cpu_5m_avg'=48.00%;0:2;0:0;0;100 'cpu_5s'=60.00%;;;0;100 'cpu_1m'=57.00%;;;0;100 'cpu_5m'=48.00%;;;0;100
