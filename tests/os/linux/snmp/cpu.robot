*** Settings ***
Documentation       Check cpu table

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

#Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::linux::snmp::plugin
${CGS_CMD}   ${CENTREON_GENERIC_SNMP} -j tests/os/linux/snmp/generic-snmp/cpu.json


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

cgs-cpu ${tc}
    [Tags]    os    linux    centreon-generic-snmp
    ${command}    Catenate
    ...    ${CGS_CMD}
    ...    --hostname=${HOSTNAME}
    ...    --port=${SNMPPORT}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-community=os/linux/snmp/network-interfaces
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc    extra_options                 expected_result    --
            ...       1     ${EMPTY}                      Everything is OK | 0#core.cpu.usage.percent=2%;;;0;100 avg.cpu.usage.percent=2%;;;0;100
            ...       2     --warning-avg=0.1             WARNING: avg.cpu.usage.percent is 2% | 0#core.cpu.usage.percent=2%;;;0;100 avg.cpu.usage.percent=2%;0.1;;0;100
            ...       3     --critical-avg=0.1            CRITICAL: avg.cpu.usage.percent is 2% | 0#core.cpu.usage.percent=2%;;;0;100 avg.cpu.usage.percent=2%;;0.1;0;100
            ...       4     --warning-cpu=0.1             WARNING: 0#core.cpu.usage.percent is 2% | 0#core.cpu.usage.percent=2%;0.1;;0;100 avg.cpu.usage.percent=2%;;;0;100
            ...       5     --critical-cpu=0.01           CRITICAL: 0#core.cpu.usage.percent is 2% | 0#core.cpu.usage.percent=2%;;0.01;0;100 avg.cpu.usage.percent=2%;;;0;100
