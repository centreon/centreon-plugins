*** Settings ***
Documentation       Juniper Mseries Netconf RSVP

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::juniper::mseries::netconf::plugin
    ...    --mode=rsvp
    ...    --hostname=${HOSTNAME}
    ...    --sshcli-command=get_data
    ...    --sshcli-path=${CURDIR}
    ...    --sshcli-option="-f=${CURDIR}${/}data${/}rsvp.netconf"

*** Test Cases ***
Rsvp ${tc}
    [Tags]    network    juniper    mseries    netconf
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:      tc    extraoptions    expected_result    --
            ...    1     ${EMPTY}
            ...    OK: All RSVP sessions are ok | 'rsvp.sessions.detected.count'=2;;;0;
            ...    2     ${EMPTY}
            ...    OK: All RSVP sessions are ok | 'rsvp.sessions.detected.count'=2;;;0; 'Egress~FROM-MX2-TO-MX1#rsvp.session.lsp.traffic.bytespersecond'=0;;;0; 'Ingress~FROM-MX1-TO-MX2#rsvp.session.lsp.traffic.bytespersecond'=0;;;0;
            ...    3     --filter-name=FROM-MX1-TO-MX2
            ...    OK: RSVP session 'FROM-MX1-TO-MX2' [type: Ingress, srcAddress: 10.0.0.1, dstAddress: 10.0.0.2] lsp state: Up, rsvp-session-lsp-traffic : Buffer creation | 'rsvp.sessions.detected.count'=1;;;0;
            ...    4     --filter-type=Ingress
            ...    OK: RSVP session 'FROM-MX1-TO-MX2' [type: Ingress, srcAddress: 10.0.0.1, dstAddress: 10.0.0.2] lsp state: Up, rsvp-session-lsp-traffic : Buffer creation | 'rsvp.sessions.detected.count'=1;;;0;
            ...    5     --unknown-status='\\\%{type} eq "Ingress" and \\\%{name} eq "FROM-MX1-TO-MX2"'
            ...    UNKNOWN: RSVP session 'FROM-MX1-TO-MX2' [type: Ingress, srcAddress: 10.0.0.1, dstAddress: 10.0.0.2] lsp state: Up | 'rsvp.sessions.detected.count'=2;;;0; 'Egress~FROM-MX2-TO-MX1#rsvp.session.lsp.traffic.bytespersecond'=0;;;0; 'Ingress~FROM-MX1-TO-MX2#rsvp.session.lsp.traffic.bytespersecond'=0;;;0;
            ...    6     --warning-status='\\\%{srcAddress} eq "10.0.0.2" and \\\%{dstAddress} eq "10.0.0.1"'
            ...    WARNING: RSVP session 'FROM-MX2-TO-MX1' [type: Egress, srcAddress: 10.0.0.2, dstAddress: 10.0.0.1] lsp state: Up | 'rsvp.sessions.detected.count'=2;;;0; 'Egress~FROM-MX2-TO-MX1#rsvp.session.lsp.traffic.bytespersecond'=0;;;0; 'Ingress~FROM-MX1-TO-MX2#rsvp.session.lsp.traffic.bytespersecond'=0;;;0;
            ...    7     --critical-status='\\\%{lspState} eq "Up"'
            ...    CRITICAL: RSVP session 'FROM-MX2-TO-MX1' [type: Egress, srcAddress: 10.0.0.2, dstAddress: 10.0.0.1] lsp state: Up - RSVP session 'FROM-MX1-TO-MX2' [type: Ingress, srcAddress: 10.0.0.1, dstAddress: 10.0.0.2] lsp state: Up | 'rsvp.sessions.detected.count'=2;;;0; 'Egress~FROM-MX2-TO-MX1#rsvp.session.lsp.traffic.bytespersecond'=0;;;0; 'Ingress~FROM-MX1-TO-MX2#rsvp.session.lsp.traffic.bytespersecond'=0;;;0;
            ...    8     --warning-rsvp-sessions-detected=1
            ...    WARNING: Number of RSVP sessions detected: 2 | 'rsvp.sessions.detected.count'=2;0:1;;0; 'Egress~FROM-MX2-TO-MX1#rsvp.session.lsp.traffic.bytespersecond'=0;;;0; 'Ingress~FROM-MX1-TO-MX2#rsvp.session.lsp.traffic.bytespersecond'=0;;;0;
            ...    9     --critical-rsvp-sessions-detected=1
            ...    CRITICAL: Number of RSVP sessions detected: 2 | 'rsvp.sessions.detected.count'=2;;0:1;0; 'Egress~FROM-MX2-TO-MX1#rsvp.session.lsp.traffic.bytespersecond'=0;;;0; 'Ingress~FROM-MX1-TO-MX2#rsvp.session.lsp.traffic.bytespersecond'=0;;;0;
            ...    10    --warning-rsvp-session-lsp-traffic=@0
            ...    WARNING: RSVP session 'FROM-MX2-TO-MX1' [type: Egress, srcAddress: 10.0.0.2, dstAddress: 10.0.0.1] traffic: 0.00 B/s - RSVP session 'FROM-MX1-TO-MX2' [type: Ingress, srcAddress: 10.0.0.1, dstAddress: 10.0.0.2] traffic: 0.00 B/s | 'rsvp.sessions.detected.count'=2;;;0; 'Egress~FROM-MX2-TO-MX1#rsvp.session.lsp.traffic.bytespersecond'=0;@0:0;;0; 'Ingress~FROM-MX1-TO-MX2#rsvp.session.lsp.traffic.bytespersecond'=0;@0:0;;0;
            ...    11    --critical-rsvp-session-lsp-traffic=@0
            ...    CRITICAL: RSVP session 'FROM-MX2-TO-MX1' [type: Egress, srcAddress: 10.0.0.2, dstAddress: 10.0.0.1] traffic: 0.00 B/s - RSVP session 'FROM-MX1-TO-MX2' [type: Ingress, srcAddress: 10.0.0.1, dstAddress: 10.0.0.2] traffic: 0.00 B/s | 'rsvp.sessions.detected.count'=2;;;0; 'Egress~FROM-MX2-TO-MX1#rsvp.session.lsp.traffic.bytespersecond'=0;;@0:0;0; 'Ingress~FROM-MX1-TO-MX2#rsvp.session.lsp.traffic.bytespersecond'=0;;@0:0;0;
