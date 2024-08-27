*** Settings ***
Documentation       Check arp table

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::linux::snmp::plugin


*** Test Cases ***
tcpcon ${tc}
    [Tags]    os    linux
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=tcpcon
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/linux/snmp/linux
    ...    --snmp-timeout=1
    ...    ${extra_options}

    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
 
    Should Match Regexp    ${output}    OK: Total connections: \d+ \| 'service_total'=\d+;;;;


    Examples:        tc    extra_options                           expected_result    --
            ...      1     --verbose --help                        OK: Total connections: 43 | 'service_total'=43;;;0;
            ...      2     -application=[services]                 OK: Total connections: 43 | 'service_total'=43;;;0;
            ...      3     -application=[threshold-critical]       OK: Total connections: 43 | 'service_total'=43;;;0; 'con_finWait1'=0;;;0; 'con_finWait2'=1;;;0; 'con_established'=8;;;0; 'con_listen'=17;;;0; 'con_closeWait'=1;;;0; 'con_lastAck'=0;;;0; 'con_synSent'=0;;;0; 'con_closing'=0;;;0; 'con_closed'=0;;;0; 'con_timeWait'=33;;;0; 'con_synReceived'=0;;;0;
            ...      4     -application=[threshold-warning]        OK: Total connections: 43 | 'service_total'=43;;;0; 'con_closing'=0;;;0; 'con_synSent'=0;;;0; 'con_closed'=0;;;0; 'con_finWait1'=0;;;0; 'con_closeWait'=1;;;0; 'con_established'=8;;;0; 'con_finWait2'=1;;;0; 'con_synReceived'=0;;;0; 'con_listen'=17;;;0; 'con_lastAck'=0;;;0; 'con_timeWait'=33;;;0;

*** Keywords ***
Check Elements Presence
    [Arguments]    ${output}    ${expected_result}
    :FOR    ${element}    IN    @{expected_result}
    \    Should Contain    ${output}    ${element}
