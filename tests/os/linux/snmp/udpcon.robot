*** Settings ***
Documentation       Check udpcon table

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::linux::snmp::plugin


*** Test Cases ***
udpcon ${tc}
    [Tags]    os    linux
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=udpcon
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/linux/snmp/linux
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                           expected_result    --
            ...      1     --verbose                               OK: Total connections: 7 | 'service_total'=7;;;0; 'con_listen'=7;;;0;
            ...      2     -application=[services]                 OK: Total connections: 7 | 'service_total'=7;;;0; 'con_listen'=7;;;0;
            ...      3     -application=[threshold-critical]       OK: Total connections: 7 | 'service_total'=7;;;0; 'con_listen'=7;;;0;
            ...      4     -application=[threshold-warning]        OK: Total connections: 7 | 'service_total'=7;;;0; 'con_listen'=7;;;0;