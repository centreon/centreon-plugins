*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::fortinet::fortigate::snmp::plugin


*** Test Cases ***
switch-usage ${tc}
    [Tags]    network    switch-usage
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=switch-usage
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/fortinet/fortigate/snmp/slim_fortigate-switches
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                          expected_result    --
            ...      1     ${EMPTY}                                               OK: All switches are ok | 'cpu_Anonymized 188'=21.00%;;;0;100 'memory_Anonymized 188'=38.00%;;;0;100 'cpu_Anonymized 152'=7.00%;;;0;100 'memory_Anonymized 152'=65.00%;;;0;100
            ...      2     --warning-cpu=10                                       WARNING: Switch 'Anonymized 188' cpu usage: 21.00 % | 'cpu_Anonymized 188'=21.00%;0:10;;0;100 'memory_Anonymized 188'=38.00%;;;0;100 'cpu_Anonymized 152'=7.00%;0:10;;0;100 'memory_Anonymized 152'=65.00%;;;0;100
            ...      3     --critical-cpu=10                                      CRITICAL: Switch 'Anonymized 188' cpu usage: 21.00 % | 'cpu_Anonymized 188'=21.00%;;0:10;0;100 'memory_Anonymized 188'=38.00%;;;0;100 'cpu_Anonymized 152'=7.00%;;0:10;0;100 'memory_Anonymized 152'=65.00%;;;0;100
            ...      4     --warning-memory=10                                    WARNING: Switch 'Anonymized 188' memory usage: 38.00 % - Switch 'Anonymized 152' memory usage: 65.00 % | 'cpu_Anonymized 188'=21.00%;;;0;100 'memory_Anonymized 188'=38.00%;0:10;;0;100 'cpu_Anonymized 152'=7.00%;;;0;100 'memory_Anonymized 152'=65.00%;0:10;;0;100
            ...      5     --critical-memory=10                                   CRITICAL: Switch 'Anonymized 188' memory usage: 38.00 % - Switch 'Anonymized 152' memory usage: 65.00 % | 'cpu_Anonymized 188'=21.00%;;;0;100 'memory_Anonymized 188'=38.00%;;0:10;0;100 'cpu_Anonymized 152'=7.00%;;;0;100 'memory_Anonymized 152'=65.00%;;0:10;0;100
            ...      6     --filter-name='Anonymized 188'                         OK: Switch 'Anonymized 188' status: up [admin: authorized], cpu usage: 21.00 %, memory usage: 38.00 % | 'cpu'=21.00%;;;0;100 'memory'=38.00%;;;0;100
            ...      7     --filter-ip=''                                         OK: All switches are ok | 'cpu_Anonymized 188'=21.00%;;;0;100 'memory_Anonymized 188'=38.00%;;;0;100 'cpu_Anonymized 152'=7.00%;;;0;100 'memory_Anonymized 152'=65.00%;;;0;100
            ...      8     --unknown-status='\\\%{admin} eq "authorized"'         UNKNOWN: Switch 'Anonymized 188' status: up [admin: authorized] - Switch 'Anonymized 152' status: up [admin: authorized] | 'cpu_Anonymized 188'=21.00%;;;0;100 'memory_Anonymized 188'=38.00%;;;0;100 'cpu_Anonymized 152'=7.00%;;;0;100 'memory_Anonymized 152'=65.00%;;;0;100
            ...      9     --warning-status='\\\%{status} eq "up"'                WARNING: Switch 'Anonymized 188' status: up [admin: authorized] - Switch 'Anonymized 152' status: up [admin: authorized] | 'cpu_Anonymized 188'=21.00%;;;0;100 'memory_Anonymized 188'=38.00%;;;0;100 'cpu_Anonymized 152'=7.00%;;;0;100 'memory_Anonymized 152'=65.00%;;;0;100
            ...      10    --critical-status='\\\%{status} ne "down"'             CRITICAL: Switch 'Anonymized 188' status: up [admin: authorized] - Switch 'Anonymized 152' status: up [admin: authorized] | 'cpu_Anonymized 188'=21.00%;;;0;100 'memory_Anonymized 188'=38.00%;;;0;100 'cpu_Anonymized 152'=7.00%;;;0;100 'memory_Anonymized 152'=65.00%;;;0;100
