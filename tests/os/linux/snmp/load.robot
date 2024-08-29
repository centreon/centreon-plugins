*** Settings ***
Documentation       Check load table

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::linux::snmp::plugin


*** Test Cases ***
load ${tc}
    [Tags]    os    linux
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=load
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/linux/snmp/linux
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                   expected_result    --
            ...      1     --critical=15                   OK: Load average: 0.87, 0.63, 0.47 | 'load1'=0.87;;0:15;0; 'load5'=0.63;;;0; 'load15'=0.47;;;0; 
            ...      2     --critical='2'                  OK: Load average: 0.87, 0.63, 0.47 | 'load1'=0.87;;0:2;0; 'load5'=0.63;;;0; 'load15'=0.47;;;0;
            ...      3     --warning='1'                   OK: Load average: 0.87, 0.63, 0.47 | 'load1'=0.87;0:1;;0; 'load5'=0.63;;;0; 'load15'=0.47;;;0;
            ...      4     --critical='0'                  CRITICAL: Load average: 0.87, 0.63, 0.47 | 'load1'=0.87;;0:0;0; 'load5'=0.63;;;0; 'load15'=0.47;;;0; 
            ...      5     --warning='3'                   OK: Load average: 0.87, 0.63, 0.47 | 'load1'=0.87;0:3;;0; 'load5'=0.63;;;0; 'load15'=0.47;;;0;
            ...      6     --average='0.87'                OK: Load average: 0.43 [0.87/2 CPUs], 0.32 [0.63/2 CPUs], 0.23 [0.47/2 CPUs] | 'avg_load1'=0.43;;;0; 'avg_load5'=0.32;;;0; 'avg_load15'=0.23;;;0; 'load1'=0.87;;;0; 'load5'=0.63;;;0; 'load15'=0.47;;;0; 
