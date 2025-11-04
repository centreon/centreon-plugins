*** Settings ***
Documentation       HP Athonet Node Exporter plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}         ${CURDIR}${/}mockoon.json

${BASE_URL}             http://${HOSTNAME}:${APIPORT}
${CMD}                  ${CENTREON_PLUGINS} --plugin=network::hp::athonet::nodeexporter::api::plugin --mode=smf --hostname=${HOSTNAME} --port=${APIPORT} --proto http --api-username=1 --api-password=1



*** Test Cases ***
SMF (Session Management Function) ${tc}
    [Tags]    network    hp    api


    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc  extra_options                                                            expected_result    --
            ...       1   ${EMPTY}                                                                 OK: Number of sessions: 13, supi: 13 - SBI registration network functionstatus: registered - PFCP local IP '172.42.2.9' remote IP '172.42.2.8' status: up - Peer remote IP '172.42.2.8' target type 'smf' is blacklisted: no | 'smf.sessions.count'=13;;;0; 'smf.supi.count'=13;;;0; 'sbi.nf.registration.detected.count'=1;;;0; 'sbi.nf.registration.registered.count'=1;;;0;1 'sbi.nf.registration.suspended.count'=0;;;0;1 'smf~172.42.2.8#peer.blacklisted.count'=0;;;0;
            ...       2   --unknown-sbi-nf-registration-status='%\\{status\\} eq "registered"'     UNKNOWN: SBI registration network functionstatus: registered | 'smf.sessions.count'=13;;;0; 'smf.supi.count'=13;;;0; 'sbi.nf.registration.detected.count'=1;;;0; 'sbi.nf.registration.registered.count'=1;;;0;1 'sbi.nf.registration.suspended.count'=0;;;0;1 'smf~172.42.2.8#peer.blacklisted.count'=0;;;0;
            ...       3   --warning-sbi-nf-registration-status='%\\{status\\} eq "registered"'     WARNING: SBI registration network functionstatus: registered | 'smf.sessions.count'=13;;;0; 'smf.supi.count'=13;;;0; 'sbi.nf.registration.detected.count'=1;;;0; 'sbi.nf.registration.registered.count'=1;;;0;1 'sbi.nf.registration.suspended.count'=0;;;0;1 'smf~172.42.2.8#peer.blacklisted.count'=0;;;0;
            ...       4   --critical-sbi-nf-registration-status='%\\{status\\} eq "registered"'    CRITICAL: SBI registration network functionstatus: registered | 'smf.sessions.count'=13;;;0; 'smf.supi.count'=13;;;0; 'sbi.nf.registration.detected.count'=1;;;0; 'sbi.nf.registration.registered.count'=1;;;0;1 'sbi.nf.registration.suspended.count'=0;;;0;1 'smf~172.42.2.8#peer.blacklisted.count'=0;;;0;
            ...       5   --warning-sbi-nf-registration-detected=0                                 WARNING: SBI registration network functiondetected: 1 | 'smf.sessions.count'=13;;;0; 'smf.supi.count'=13;;;0; 'sbi.nf.registration.detected.count'=1;0:0;;0; 'sbi.nf.registration.registered.count'=1;;;0;1 'sbi.nf.registration.suspended.count'=0;;;0;1 'smf~172.42.2.8#peer.blacklisted.count'=0;;;0;
            ...       6   --critical-sbi-nf-registration-detected=0                                CRITICAL: SBI registration network functiondetected: 1 | 'smf.sessions.count'=13;;;0; 'smf.supi.count'=13;;;0; 'sbi.nf.registration.detected.count'=1;;0:0;0; 'sbi.nf.registration.registered.count'=1;;;0;1 'sbi.nf.registration.suspended.count'=0;;;0;1 'smf~172.42.2.8#peer.blacklisted.count'=0;;;0;
            ...       7   --warning-sbi-nf-registration-registered=0                               WARNING: SBI registration network functionregistered: 1 | 'smf.sessions.count'=13;;;0; 'smf.supi.count'=13;;;0; 'sbi.nf.registration.detected.count'=1;;;0; 'sbi.nf.registration.registered.count'=1;0:0;;0;1 'sbi.nf.registration.suspended.count'=0;;;0;1 'smf~172.42.2.8#peer.blacklisted.count'=0;;;0;
            ...       8   --critical-sbi-nf-registration-registered=0                              CRITICAL: SBI registration network functionregistered: 1 | 'smf.sessions.count'=13;;;0; 'smf.supi.count'=13;;;0; 'sbi.nf.registration.detected.count'=1;;;0; 'sbi.nf.registration.registered.count'=1;;0:0;0;1 'sbi.nf.registration.suspended.count'=0;;;0;1 'smf~172.42.2.8#peer.blacklisted.count'=0;;;0;
            ...       9   --warning-sbi-nf-registration-suspended=1:                               WARNING: SBI registration network functionsuspended: 0 | 'smf.sessions.count'=13;;;0; 'smf.supi.count'=13;;;0; 'sbi.nf.registration.detected.count'=1;;;0; 'sbi.nf.registration.registered.count'=1;;;0;1 'sbi.nf.registration.suspended.count'=0;1:;;0;1 'smf~172.42.2.8#peer.blacklisted.count'=0;;;0;
            ...      10   --critical-sbi-nf-registration-suspended=1:                              CRITICAL: SBI registration network functionsuspended: 0 | 'smf.sessions.count'=13;;;0; 'smf.supi.count'=13;;;0; 'sbi.nf.registration.detected.count'=1;;;0; 'sbi.nf.registration.registered.count'=1;;;0;1 'sbi.nf.registration.suspended.count'=0;;1:;0;1 'smf~172.42.2.8#peer.blacklisted.count'=0;;;0;
            ...      11   --warning-sessions=0                                                     WARNING: Number of sessions: 13 | 'smf.sessions.count'=13;0:0;;0; 'smf.supi.count'=13;;;0; 'sbi.nf.registration.detected.count'=1;;;0; 'sbi.nf.registration.registered.count'=1;;;0;1 'sbi.nf.registration.suspended.count'=0;;;0;1 'smf~172.42.2.8#peer.blacklisted.count'=0;;;0;
            ...      12   --critical-sessions=0                                                    CRITICAL: Number of sessions: 13 | 'smf.sessions.count'=13;;0:0;0; 'smf.supi.count'=13;;;0; 'sbi.nf.registration.detected.count'=1;;;0; 'sbi.nf.registration.registered.count'=1;;;0;1 'sbi.nf.registration.suspended.count'=0;;;0;1 'smf~172.42.2.8#peer.blacklisted.count'=0;;;0;
            ...      13   --warning-supi=0                                                         WARNING: Number of supi: 13 | 'smf.sessions.count'=13;;;0; 'smf.supi.count'=13;0:0;;0; 'sbi.nf.registration.detected.count'=1;;;0; 'sbi.nf.registration.registered.count'=1;;;0;1 'sbi.nf.registration.suspended.count'=0;;;0;1 'smf~172.42.2.8#peer.blacklisted.count'=0;;;0;
            ...      14   --critical-supi=0                                                        CRITICAL: Number of supi: 13 | 'smf.sessions.count'=13;;;0; 'smf.supi.count'=13;;0:0;0; 'sbi.nf.registration.detected.count'=1;;;0; 'sbi.nf.registration.registered.count'=1;;;0;1 'sbi.nf.registration.suspended.count'=0;;;0;1 'smf~172.42.2.8#peer.blacklisted.count'=0;;;0;
            ...      15   --unknown-pfcp-node-status='%\\{status\\} ne "running"'                  UNKNOWN: PFCP local IP '172.42.2.9' remote IP '172.42.2.8' status: up | 'smf.sessions.count'=13;;;0; 'smf.supi.count'=13;;;0; 'sbi.nf.registration.detected.count'=1;;;0; 'sbi.nf.registration.registered.count'=1;;;0;1 'sbi.nf.registration.suspended.count'=0;;;0;1 'smf~172.42.2.8#peer.blacklisted.count'=0;;;0;
            ...      16   --warning-pfcp-node-status='%\\{status\\} ne "running"'                  WARNING: PFCP local IP '172.42.2.9' remote IP '172.42.2.8' status: up | 'smf.sessions.count'=13;;;0; 'smf.supi.count'=13;;;0; 'sbi.nf.registration.detected.count'=1;;;0; 'sbi.nf.registration.registered.count'=1;;;0;1 'sbi.nf.registration.suspended.count'=0;;;0;1 'smf~172.42.2.8#peer.blacklisted.count'=0;;;0;
            ...      17   --critical-pfcp-node-status='%\\{status\\} ne "running"'                 CRITICAL: PFCP local IP '172.42.2.9' remote IP '172.42.2.8' status: up | 'smf.sessions.count'=13;;;0; 'smf.supi.count'=13;;;0; 'sbi.nf.registration.detected.count'=1;;;0; 'sbi.nf.registration.registered.count'=1;;;0;1 'sbi.nf.registration.suspended.count'=0;;;0;1 'smf~172.42.2.8#peer.blacklisted.count'=0;;;0;
            ...      18   --unknown-blacklist-node-status='%\\{isBlacklisted\\} eq "no"'           UNKNOWN: Peer remote IP '172.42.2.8' target type 'smf' is blacklisted: no | 'smf.sessions.count'=13;;;0; 'smf.supi.count'=13;;;0; 'sbi.nf.registration.detected.count'=1;;;0; 'sbi.nf.registration.registered.count'=1;;;0;1 'sbi.nf.registration.suspended.count'=0;;;0;1 'smf~172.42.2.8#peer.blacklisted.count'=0;;;0;
            ...      19   --warning-blacklist-node-status='%\\{isBlacklisted\\} eq "no"'           WARNING: Peer remote IP '172.42.2.8' target type 'smf' is blacklisted: no | 'smf.sessions.count'=13;;;0; 'smf.supi.count'=13;;;0; 'sbi.nf.registration.detected.count'=1;;;0; 'sbi.nf.registration.registered.count'=1;;;0;1 'sbi.nf.registration.suspended.count'=0;;;0;1 'smf~172.42.2.8#peer.blacklisted.count'=0;;;0;
            ...      20   --critical-blacklist-node-status='%\\{isBlacklisted\\} eq "no"'          CRITICAL: Peer remote IP '172.42.2.8' target type 'smf' is blacklisted: no | 'smf.sessions.count'=13;;;0; 'smf.supi.count'=13;;;0; 'sbi.nf.registration.detected.count'=1;;;0; 'sbi.nf.registration.registered.count'=1;;;0;1 'sbi.nf.registration.suspended.count'=0;;;0;1 'smf~172.42.2.8#peer.blacklisted.count'=0;;;0;
