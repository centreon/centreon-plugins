*** Settings ***
Documentation       Check cpu table

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::linux::snmp::plugin


*** Test Cases ***
cpu ${tc}
    [Tags]    os    linux
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=cpu
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/linux/snmp/network-interfaces
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                   expected_result    --
            ...      1     --use-ucd='0'                   OK: 1 CPU(s) average usage is 2.00 % - CPU '0' usage : 2.00 % | 'total_cpu_avg'=2.00%;;;0;100 'cpu'=2.00%;;;0;100
            ...      2     --warning-average               OK: 1 CPU(s) average usage is 2.00 % - CPU '0' usage : 2.00 % | 'total_cpu_avg'=2.00%;;;0;100 'cpu'=2.00%;;;0;100
            ...      3     --critical-average              OK: 1 CPU(s) average usage is 2.00 % - CPU '0' usage : 2.00 % | 'total_cpu_avg'=2.00%;;;0;100 'cpu'=2.00%;;;0;100
            ...      4     --warning-core                  OK: 1 CPU(s) average usage is 2.00 % - CPU '0' usage : 2.00 % | 'total_cpu_avg'=2.00%;;;0;100 'cpu'=2.00%;;;0;100
            ...      5     --critical-core                 OK: 1 CPU(s) average usage is 2.00 % - CPU '0' usage : 2.00 % | 'total_cpu_avg'=2.00%;;;0;100 'cpu'=2.00%;;;0;100
            ...      6     --verbose                       OK: 1 CPU(s) average usage is 2.00 % - CPU '0' usage : 2.00 % | 'total_cpu_avg'=2.00%;;;0;100 'cpu'=2.00%;;;0;100 CPU '0' usage : 2.00 %
            ...      7     --warning-average='0'           WARNING: 1 CPU(s) average usage is 2.00 % | 'total_cpu_avg'=2.00%;0:0;;0;100 'cpu'=2.00%;;;0;100
            ...      8     --critical-average='0'          CRITICAL: 1 CPU(s) average usage is 2.00 % | 'total_cpu_avg'=2.00%;;0:0;0;100 'cpu'=2.00%;;;0;100
            ...      9     --warning-core='0'              WARNING: CPU '0' usage : 2.00 % | 'total_cpu_avg'=2.00%;;;0;100 'cpu'=2.00%;0:0;;0;100
            ...      10    --critical-core='0'             CRITICAL: CPU '0' usage : 2.00 % | 'total_cpu_avg'=2.00%;;;0;100 'cpu'=2.00%;;0:0;0;100