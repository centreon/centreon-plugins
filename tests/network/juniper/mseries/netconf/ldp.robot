*** Settings ***
Documentation       Juniper Mseries Netconf LDP

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::juniper::mseries::netconf::plugin
    ...    --mode=ldp
    ...    --hostname=${HOSTNAME}
    ...    --sshcli-command=get_data
    ...    --sshcli-path=${CURDIR}
    ...    --sshcli-option="-f=${CURDIR}${/}data${/}ldp.netconf"

*** Test Cases ***
Ldp ${tc}
    [Tags]    network    juniper    mseries    netconf
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:      tc    extraoptions    expected_result    --
            ...    1     ${EMPTY}
            ...    OK: All LDP sessions are ok | 'ldp.sessions.detected.count'=4;;;0;
            ...    2     --filter-id="10.0.0.1:0--10.0.0.4:0"
            ...    OK: LDP session '10.0.0.4' connection state: Open, session state: Operational | 'ldp.sessions.detected.count'=1;;;0;
            ...    3     --filter-remote-address=10.0.0.6
            ...    OK: LDP session '10.0.0.6' connection state: Open, session state: Operational | 'ldp.sessions.detected.count'=1;;;0;
            ...    4     --unknown-status='\\\%{id} eq "10.0.0.1:0--10.0.0.2:0" and \\\%{remoteAddress} eq "10.0.0.2"'
            ...    UNKNOWN: LDP session '10.0.0.2' connection state: Open, session state: Operational | 'ldp.sessions.detected.count'=4;;;0;
            ...    5     --warning-status='\\\%{id} eq "10.0.0.1:0--10.0.0.4:0" and \\\%{connectionState} eq "Open"'
            ...    WARNING: LDP session '10.0.0.4' connection state: Open, session state: Operational | 'ldp.sessions.detected.count'=4;;;0;
            ...    6     --critical-status='\\\%{id} eq "10.0.0.1:0--10.0.0.6:0" and \\\%{sessionState} eq "Operational"'
            ...    CRITICAL: LDP session '10.0.0.6' connection state: Open, session state: Operational | 'ldp.sessions.detected.count'=4;;;0;
            ...    7     --warning-ldp-sessions-detected=2
            ...    WARNING: Number of LDP sessions detected: 4 | 'ldp.sessions.detected.count'=4;0:2;;0;
            ...    8     --critical-ldp-sessions-detected=3
            ...    CRITICAL: Number of LDP sessions detected: 4 | 'ldp.sessions.detected.count'=4;;0:3;0;
