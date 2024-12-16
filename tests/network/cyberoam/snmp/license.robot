*** Settings ***
Documentation       Check current HA-State. HA-States: notapplicable, auxiliary, standAlone,primary, faulty, ready.

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Test Setup          Ctn Generic Suite Setup

*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::cyberoam::snmp::plugin


*** Test Cases ***
ha-status ${tc}
    [Tags]    network    cyberoam
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=ha-status
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/cyberoam/snmp/slim_sophos
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                                                                                                                             expected_result    --
            ...      1     ${EMPTY}                                                                                                                                                                                 OK: Current HA State: 'primary' Peer HA State: 'auxiliary' HA Port: 'Anonymized 007' HA IP: '192.168.42.167' Peer IP: '192.168.42.23'
            ...      2     --warning-status=\\\%{hastatus}                                                                                                                                                           OK: Current HA State: 'primary' Peer HA State: 'auxiliary' HA Port: 'Anonymized 007' HA IP: '192.168.42.167' Peer IP: '192.168.42.23'
            ...      3     --critical-status='\\\%{hastatus} ne "primary"'                                                                                                                                           CRITICAL: Current HA State: 'primary' Peer HA State: 'auxiliary' HA Port: 'Anonymized 007' HA IP: '192.168.42.167' Peer IP: '192.168.42.23'
            ...      4     --no-ha-status='Critical'                                                                                                                                                                 OK: Current HA State: 'primary' Peer HA State: 'auxiliary' HA Port: 'Anonymized 007' HA IP: '192.168.42.167' Peer IP: '192.168.42.23'
            ...      5     --warning-status='\\\%{hastatus} ne "primary"'                                                                                                                                            WARNING: Current HA State: 'primary' Peer HA State: 'auxiliary' HA Port: 'Anonymized 007' HA IP: '192.168.42.167' Peer IP: '192.168.42.23'
            ...      6     --warning-status='\\\%{hastatus} eq "enabled"'                                                                                                                                            OK: Current HA State: 'primary' Peer HA State: 'auxiliary' HA Port: 'Anonymized 007' HA IP: '192.168.42.167' Peer IP: '192.168.42.23'
            ...      7     --critical-status='\\\%{peer_hastate} ne "auxiliary"'                                                                                                                                     OK: Current HA State: 'primary' Peer HA State: 'auxiliary' HA Port: 'Anonymized 007' HA IP: '192.168.42.167' Peer IP: '192.168.42.23'
            ...      8     --critical-status='\\\%{peer_hastate} ne "primary"'                                                                                                                                       CRITICAL: Current HA State: 'primary' Peer HA State: 'auxiliary' HA Port: 'Anonymized 007' HA IP: '192.168.42.167' Peer IP: '192.168.42.23'