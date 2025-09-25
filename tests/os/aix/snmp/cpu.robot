*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::aix::snmp::plugin


*** Test Cases ***
cpu ${tc}
    [Tags]    os    aix
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=cpu
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/aix/snmp/slim_os-aix
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                   expected_result    --
            ...      1     --verbose                                       OK: 8 CPU(s) average usage is 17.50 % | 'total_cpu_avg'=17.50%;;;0;100 'cpu_0'=91.00%;;;0;100 'cpu_1'=22.00%;;;0;100 'cpu_2'=13.00%;;;0;100 'cpu_3'=6.00%;;;0;100 'cpu_4'=0.00%;;;0;100 'cpu_5'=1.00%;;;0;100 'cpu_6'=6.00%;;;0;100 'cpu_7'=1.00%;;;0;100 CPU '0' usage : 91.00 % CPU '1' usage : 22.00 % CPU '2' usage : 13.00 % CPU '3' usage : 6.00 % CPU '4' usage : 0.00 % CPU '5' usage : 1.00 % CPU '6' usage : 6.00 % CPU '7' usage : 1.00 %
            ...      2     --warning-average=3 --critical-average=5        CRITICAL: 8 CPU(s) average usage is 17.50 % | 'total_cpu_avg'=17.50%;0:3;0:5;0;100 'cpu_0'=91.00%;;;0;100 'cpu_1'=22.00%;;;0;100 'cpu_2'=13.00%;;;0;100 'cpu_3'=6.00%;;;0;100 'cpu_4'=0.00%;;;0;100 'cpu_5'=1.00%;;;0;100 'cpu_6'=6.00%;;;0;100 'cpu_7'=1.00%;;;0;100 
            ...      3     --warning-core=5                                WARNING: CPU '0' usage : 91.00 % - CPU '1' usage : 22.00 % - CPU '2' usage : 13.00 % - CPU '3' usage : 6.00 % - CPU '6' usage : 6.00 % | 'total_cpu_avg'=17.50%;;;0;100 'cpu_0'=91.00%;0:5;;0;100 'cpu_1'=22.00%;0:5;;0;100 'cpu_2'=13.00%;0:5;;0;100 'cpu_3'=6.00%;0:5;;0;100 'cpu_4'=0.00%;0:5;;0;100 'cpu_5'=1.00%;0:5;;0;100 'cpu_6'=6.00%;0:5;;0;100 'cpu_7'=1.00%;0:5;;0;100
            ...      4     --warning-core=3 --critical-core=5              CRITICAL: CPU '0' usage : 91.00 % - CPU '1' usage : 22.00 % - CPU '2' usage : 13.00 % - CPU '3' usage : 6.00 % - CPU '6' usage : 6.00 % | 'total_cpu_avg'=17.50%;;;0;100 'cpu_0'=91.00%;0:3;0:5;0;100 'cpu_1'=22.00%;0:3;0:5;0;100 'cpu_2'=13.00%;0:3;0:5;0;100 'cpu_3'=6.00%;0:3;0:5;0;100 'cpu_4'=0.00%;0:3;0:5;0;100 'cpu_5'=1.00%;0:3;0:5;0;100 'cpu_6'=6.00%;0:3;0:5;0;100 'cpu_7'=1.00%;0:3;0:5;0;100 