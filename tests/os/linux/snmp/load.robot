*** Settings ***
Documentation       Check load table

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s

*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::linux::snmp::plugin


*** Test Cases ***
load ${tc}
    [Tags]    os    linux     snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=load
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/linux/snmp/linux
    ...    --snmp-timeout=1
    ...    --critical=${critical}
    ...    --warning=${warning}
    ...    --average
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:        tc     critical         warning           extra_options            expected_result    --
            ...      1      '6,5,4'          '4,3,2'           ${EMPTY}           OK: Load average: 0.43 [0.87/2 CPUs], 0.32 [0.63/2 CPUs], 0.23 [0.47/2 CPUs] | 'avg_load1'=0.43;0:4;0:6;0; 'avg_load5'=0.32;0:3;0:5;0; 'avg_load15'=0.23;0:2;0:4;0; 'load1'=0.87;0:8;0:12;0; 'load5'=0.63;0:6;0:10;0; 'load15'=0.47;0:4;0:8;0; 
            ...      2      '0,0,0'          '4,3,2'           ${EMPTY}           CRITICAL: Load average: 0.43 [0.87/2 CPUs], 0.32 [0.63/2 CPUs], 0.23 [0.47/2 CPUs] | 'avg_load1'=0.43;0:4;0:0;0; 'avg_load5'=0.32;0:3;0:0;0; 'avg_load15'=0.23;0:2;0:0;0; 'load1'=0.87;0:8;0:0;0; 'load5'=0.63;0:6;0:0;0; 'load15'=0.47;0:4;0:0;0;
            ...      3      '600,500,100'    '0,0,0'           ${EMPTY}           WARNING: Load average: 0.43 [0.87/2 CPUs], 0.32 [0.63/2 CPUs], 0.23 [0.47/2 CPUs] | 'avg_load1'=0.43;0:0;0:600;0; 'avg_load5'=0.32;0:0;0:500;0; 'avg_load15'=0.23;0:0;0:100;0; 'load1'=0.87;0:0;0:1200;0; 'load5'=0.63;0:0;0:1000;0; 'load15'=0.47;0:0;0:200;0;
            ...      4      '6,5,4'          '4,3,2'           --change-output-adv='%(short_output) =~ /OK:/ and %(exit_code) == 0,Forced from OK to WARNING,WARNING'           Forced from OK to WARNING| 'avg_load1'=0.43;0:4;0:6;0; 'avg_load5'=0.32;0:3;0:5;0; 'avg_load15'=0.23;0:2;0:4;0; 'load1'=0.87;0:8;0:12;0; 'load5'=0.63;0:6;0:10;0; 'load15'=0.47;0:4;0:8;0;
            ...      5      '0,0,0'          '4,3,2'           --change-output-adv='%(short_output) =~ /CRITICAL:/ and %(exit_code) == 2,Forced from CRITICAL to OK,OK'           Forced from CRITICAL to OK| 'avg_load1'=0.43;0:4;0:0;0; 'avg_load5'=0.32;0:3;0:0;0; 'avg_load15'=0.23;0:2;0:0;0; 'load1'=0.87;0:8;0:0;0; 'load5'=0.63;0:6;0:0;0; 'load15'=0.47;0:4;0:0;0;
            ...      6      '600,500,100'    '0,0,0'           --change-output-adv='%(short_output) =~ /WARNING:/ and %(exit_code) == 1,Forced from WARNING to CRITICAL,CRITICAL'           Forced from WARNING to CRITICAL| 'avg_load1'=0.43;0:0;0:600;0; 'avg_load5'=0.32;0:0;0:500;0; 'avg_load15'=0.23;0:0;0:100;0; 'load1'=0.87;0:0;0:1200;0; 'load5'=0.63;0:0;0:1000;0; 'load15'=0.47;0:0;0:200;0;
