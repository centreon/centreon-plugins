*** Settings ***
Documentation       Forcepoint SD-WAN Mode Cpu

Resource            ${CURDIR}${/}../..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}                                          ${CENTREON_PLUGINS} --plugin=network::forcepoint::sdwan::snmp::plugin


*** Test Cases ***
cpu ${tc}
    [Tags]    network    forcepoint    sdwan     snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=cpu
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=40000
    ...    --snmp-community=network/forcepoint/sdwan/snmp/forcepoint-cpu
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                   expected_result    --
            ...      1     --use-ucd='0'                   OK: 2 CPU(s) average usage is 3.00 % | 'total_cpu_avg'=3.00%;;;0;100 'cpu_0'=4.00%;;;0;100 'cpu_1'=2.00%;;;0;100
            ...      2     --warning-average               OK: 2 CPU(s) average usage is 3.00 % | 'total_cpu_avg'=3.00%;;;0;100 'cpu_0'=4.00%;;;0;100 'cpu_1'=2.00%;;;0;100
            ...      3     --critical-average              OK: 2 CPU(s) average usage is 3.00 % | 'total_cpu_avg'=3.00%;;;0;100 'cpu_0'=4.00%;;;0;100 'cpu_1'=2.00%;;;0;100
            ...      4     --warning-core                  OK: 2 CPU(s) average usage is 3.00 % | 'total_cpu_avg'=3.00%;;;0;100 'cpu_0'=4.00%;;;0;100 'cpu_1'=2.00%;;;0;100
            ...      5     --critical-core                 OK: 2 CPU(s) average usage is 3.00 % | 'total_cpu_avg'=3.00%;;;0;100 'cpu_0'=4.00%;;;0;100 'cpu_1'=2.00%;;;0;100
            ...      6     --verbose                       OK: 2 CPU(s) average usage is 3.00 % | 'total_cpu_avg'=3.00%;;;0;100 'cpu_0'=4.00%;;;0;100 'cpu_1'=2.00%;;;0;100 CPU '0' usage : 4.00 % CPU '1' usage : 2.00 %
            ...      7     --warning-average='0'           WARNING: 2 CPU(s) average usage is 3.00 % | 'total_cpu_avg'=3.00%;0:0;;0;100 'cpu_0'=4.00%;;;0;100 'cpu_1'=2.00%;;;0;100
            ...      8     --critical-average='0'          CRITICAL: 2 CPU(s) average usage is 3.00 % | 'total_cpu_avg'=3.00%;;0:0;0;100 'cpu_0'=4.00%;;;0;100 'cpu_1'=2.00%;;;0;100
            ...      9     --warning-core='0'              WARNING: CPU '0' usage : 4.00 % - CPU '1' usage : 2.00 % | 'total_cpu_avg'=3.00%;;;0;100 'cpu_0'=4.00%;0:0;;0;100 'cpu_1'=2.00%;0:0;;0;100
            ...      10    --critical-core='0'             CRITICAL: CPU '0' usage : 4.00 % - CPU '1' usage : 2.00 % | 'total_cpu_avg'=3.00%;;;0;100 'cpu_0'=4.00%;;0:0;0;100 'cpu_1'=2.00%;;0:0;0;100
