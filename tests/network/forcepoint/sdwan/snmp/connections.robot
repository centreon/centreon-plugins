*** Settings ***
Documentation       Forcepoint SD-WAN Mode Connections

Resource            ${CURDIR}${/}../..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}                                          ${CENTREON_PLUGINS} --plugin=network::forcepoint::sdwan::snmp::plugin

*** Test Cases ***
Connections ${tc}
    [Tags]    network    forcepoint    sdwan     snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=connections
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=40000
    ...    --snmp-community=network/forcepoint/sdwan/snmp/forcepoint-connections
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                    expected_result    --
            ...      1     ${EMPTY}                                                                         OK: Total connections : 41, New Connections : 0.00 /s, Discarded Connections : 0.00 /s, Refused Connections : 0.00 /s | 'connections'=41con;;;0; 'new_connections'=0.00con/s;;;0; 'discarded_connections'=0.00con/s;;;0; 'refused_connections'=0.00con/s;;;0;
            ...      2     --filter-counters=discarded-connections-sec                                      OK: Discarded Connections : 0.00 /s | 'discarded_connections'=0.00con/s;;;0;
            ...      3     --warning-connections=:1                                                         WARNING: Total connections : 41 | 'connections'=41con;0:1;;0; 'new_connections'=0.00con/s;;;0; 'discarded_connections'=0.00con/s;;;0; 'refused_connections'=0.00con/s;;;0;
            ...      4     --critical-discarded-connections-sec=1:                                          CRITICAL: Discarded Connections : 0.00 /s | 'connections'=41con;;;0; 'new_connections'=0.00con/s;;;0; 'discarded_connections'=0.00con/s;;1:;0; 'refused_connections'=0.00con/s;;;0;
            ...      5     --warning-new-connections-sec=1:                                                 WARNING: New Connections : 0.00 /s | 'connections'=41con;;;0; 'new_connections'=0.00con/s;1:;;0; 'discarded_connections'=0.00con/s;;;0; 'refused_connections'=0.00con/s;;;0;
            ...      6     --critical-refused-connections-sec=1:                                            CRITICAL: Refused Connections : 0.00 /s | 'connections'=41con;;;0; 'new_connections'=0.00con/s;;;0; 'discarded_connections'=0.00con/s;;;0; 'refused_connections'=0.00con/s;;1:;0;
