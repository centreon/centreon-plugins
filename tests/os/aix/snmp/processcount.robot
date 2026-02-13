*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::aix::snmp::plugin


*** Test Cases ***
processcount ${tc}
    [Tags]    os    aix
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=processcount
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/aix/snmp/aix
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                   expected_result    --
            ...      1     ${EMPTY} --top                                   OK: Number of current processes running: 131 | 'nbproc'=131;;;0; 'top_'=375496704B;;;0;
            ...      2     --process-status='running|runnable'              OK: Number of current processes running: 131 | 'nbproc'=131;;;0;
            ...      3     --process-name=85                                OK: Number of current processes running: 0 | 'nbproc'=0;;;0;
            ...      4     --process-args                                   OK: Number of current processes running: 131 | 'nbproc'=131;;;0;
            ...      5     --warning=5                                      WARNING: Number of current processes running: 131 | 'nbproc'=131;0:5;;0;
            ...      6     --critical=8                                     CRITICAL: Number of current processes running: 131 | 'nbproc'=131;;0:8;0;
            ...      7     --memory                                         OK: Number of current processes running: 131 - Total memory usage: 452.86 MB - Average memory usage: 3.46 MB | 'nbproc'=131;;;0; 'mem_total'=474857472B;;;0; 'mem_avg'=3624866.20B;;;0;
            ...      8     --warning-mem-total=5 --memory                   WARNING: Total memory usage: 452.86 MB | 'nbproc'=131;;;0; 'mem_total'=474857472B;0:5;;0; 'mem_avg'=3624866.20B;;;0;
            ...      9     --critical-mem-total=4 --memory                  CRITICAL: Total memory usage: 452.86 MB | 'nbproc'=131;;;0; 'mem_total'=474857472B;;0:4;0; 'mem_avg'=3624866.20B;;;0;
            ...      10    --warning-mem-avg=3 --memory                     WARNING: Average memory usage: 3.46 MB | 'nbproc'=131;;;0; 'mem_total'=474857472B;;;0; 'mem_avg'=3624866.20B;0:3;;0;
            ...      11    --critical-mem-avg=3 --memory                    CRITICAL: Average memory usage: 3.46 MB | 'nbproc'=131;;;0; 'mem_total'=474857472B;;;0; 'mem_avg'=3624866.20B;;0:3;0;
            ...      12    --warning-cpu-total=10 --cpu                     OK: Number of current processes running: 131 | 'nbproc'=131;;;0;
            ...      13    --critical-cpu-total=5 --cpu                     OK: Number of current processes running: 131 - Total CPU usage: 0.00 % | 'nbproc'=131;;;0; 'cpu_total'=0.00%;;0:5;0;
