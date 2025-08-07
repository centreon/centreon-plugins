*** Settings ***
Documentation       Check cpu table


Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Stop Connector
Test Timeout        120s

*** Variables ***
${CMD}      /usr/lib/centreon/plugins/centreon_linux_snmp.pl --plugin=os::linux::snmp::plugin


*** Test Cases ***
cpu-connector ${tc}
    [Tags]    os    linux
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=cpu
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/linux/snmp/network-interfaces
    ...    ${extra_options}
    
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:        tc    extra_options                   expected_result    --
            ...      1     --use-ucd='0'                   OK: 1 CPU(s) average usage is 2.00 % - CPU '0' usage : 2.00 % | 'total_cpu_avg'=2.00%;;;0;100 'cpu'=2.00%;;;0;100
            ...      2     --warning-average               OK: 1 CPU(s) average usage is 2.00 % - CPU '0' usage : 2.00 % | 'total_cpu_avg'=2.00%;;;0;100 'cpu'=2.00%;;;0;100
            ...      3     --critical-average              OK: 1 CPU(s) average usage is 2.00 % - CPU '0' usage : 2.00 % | 'total_cpu_avg'=2.00%;;;0;100 'cpu'=2.00%;;;0;100
            ...      4     --warning-core                  OK: 1 CPU(s) average usage is 2.00 % - CPU '0' usage : 2.00 % | 'total_cpu_avg'=2.00%;;;0;100 'cpu'=2.00%;;;0;100
            ...      5     --critical-core                 OK: 1 CPU(s) average usage is 2.00 % - CPU '0' usage : 2.00 % | 'total_cpu_avg'=2.00%;;;0;100 'cpu'=2.00%;;;0;100
            ...      6     --warning-average='0'           WARNING: 1 CPU(s) average usage is 2.00 % | 'total_cpu_avg'=2.00%;0:0;;0;100 'cpu'=2.00%;;;0;100
            ...      7     --critical-average='0'          CRITICAL: 1 CPU(s) average usage is 2.00 % | 'total_cpu_avg'=2.00%;;0:0;0;100 'cpu'=2.00%;;;0;100
            ...      8     --warning-core='0'              WARNING: CPU '0' usage : 2.00 % | 'total_cpu_avg'=2.00%;;;0;100 'cpu'=2.00%;0:0;;0;100
            ...      9     --critical-core='0'             CRITICAL: CPU '0' usage : 2.00 % | 'total_cpu_avg'=2.00%;;;0;100 'cpu'=2.00%;;0:0;0;100
