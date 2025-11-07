*** Settings ***
Documentation       HP Athonet Node Exporter plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}         ${CURDIR}${/}mockoon.json

${BASE_URL}             http://${HOSTNAME}:${APIPORT}
${CMD}                  ${CENTREON_PLUGINS} --plugin=network::hp::athonet::nodeexporter::api::plugin --mode=pcf --hostname=${HOSTNAME} --port=${APIPORT} --proto http --api-username=1 --api-password=1



*** Test Cases ***
PCF (Network Repository Function) ${tc}
    [Tags]    network    hp    api


    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc  extra_options                                                            expected_result    --
            ...       1   ${EMPTY}                                                                 OK: Number of N7 PDN connected: 13, N5 sessions: 0 - All diameter connections are ok | 'pcf.pdn.n7.connected.count'=13;;;0; 'pcf.sessions.n5.count'=0;;;0;
            ...       2   --unknown-diameter-connection-status='%\\{status\\} !~ /down/i'          UNKNOWN: diameter stack 'diam_default' origin host 'site1-dra01-local.bjo.fgh123.klm567.domain.local' connection status: up - diameter stack 'diam_default' origin host 'site2-dra01-local.bjo.fgh123.klm567.domain.local' connection status: up | 'pcf.pdn.n7.connected.count'=13;;;0; 'pcf.sessions.n5.count'=0;;;0;
            ...       3   --warning-diameter-connection-status='%\\{status\\} !~ /down/i'          WARNING: diameter stack 'diam_default' origin host 'site1-dra01-local.bjo.fgh123.klm567.domain.local' connection status: up - diameter stack 'diam_default' origin host 'site2-dra01-local.bjo.fgh123.klm567.domain.local' connection status: up | 'pcf.pdn.n7.connected.count'=13;;;0; 'pcf.sessions.n5.count'=0;;;0;
            ...       4   --critical-diameter-connection-status='%\\{status\\} !~ /down/i'         CRITICAL: diameter stack 'diam_default' origin host 'site1-dra01-local.bjo.fgh123.klm567.domain.local' connection status: up - diameter stack 'diam_default' origin host 'site2-dra01-local.bjo.fgh123.klm567.domain.local' connection status: up | 'pcf.pdn.n7.connected.count'=13;;;0; 'pcf.sessions.n5.count'=0;;;0;
            ...       5   --warning-pdn-n7-connected=1                                             WARNING: Number of N7 PDN connected: 13 | 'pcf.pdn.n7.connected.count'=13;0:1;;0; 'pcf.sessions.n5.count'=0;;;0;
            ...       6   --critical-pdn-n7-connected=1                                            CRITICAL: Number of N7 PDN connected: 13 | 'pcf.pdn.n7.connected.count'=13;;0:1;0; 'pcf.sessions.n5.count'=0;;;0;
            ...       7   --warning-sessions-n5=1:                                                 WARNING: Number of N5 sessions: 0 | 'pcf.pdn.n7.connected.count'=13;;;0; 'pcf.sessions.n5.count'=0;1:;;0;
            ...       8   --critical-sessions-n5=1:                                                CRITICAL: Number of N5 sessions: 0 | 'pcf.pdn.n7.connected.count'=13;;;0; 'pcf.sessions.n5.count'=0;;1:;0;

