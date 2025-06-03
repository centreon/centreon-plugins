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

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:      tc    extraoptions    expected_result    --
            ...    1     ${EMPTY}
            ...    OK: All RSVP sessions are ok | 'rsvp.sessions.detected.count'=2;;;0;
            ...    2     ${EMPTY}
            ...    OK: All RSVP sessions are ok | 'rsvp.sessions.detected.count'=2;;;0; 'Egress~FROM-MX2-TO-MX1#rsvp.session.lsp.traffic.bytespersecond'=0;;;0; 'Ingress~FROM-MX1-TO-MX2#rsvp.session.lsp.traffic.bytespersecond'=0;;;0;