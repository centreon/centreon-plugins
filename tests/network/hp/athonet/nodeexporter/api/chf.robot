*** Settings ***
Documentation       HP Athonet Node Exporter plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}         ${CURDIR}${/}mockoon.json

${BASE_URL}             http://${HOSTNAME}:${APIPORT}
${CMD}                  ${CENTREON_PLUGINS} --plugin=network::hp::athonet::nodeexporter::api::plugin --mode=chf --hostname=${HOSTNAME} --port=${APIPORT} --proto http --api-username=1 --api-password=1



*** Test Cases ***
CHF (charging function) ${tc}
    [Tags]    network    hp    api
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc  extra_options                                                            expected_result    --
            ...       1   ${EMPTY}                                                                 OK: Number of active converged charging sessions: 14 - SBI registration network function status: registered | 'chf.sessions.active.charging.count'=14;;;0; 'sbi.nf.registration.detected.count'=1;;;0; 'sbi.nf.registration.registered.count'=1;;;0;1 'sbi.nf.registration.suspended.count'=0;;;0;1
            ...       2   --unknown-sbi-nf-registration-status='%\\{status\\} eq "registered"'     UNKNOWN: SBI registration network function status: registered | 'chf.sessions.active.charging.count'=14;;;0; 'sbi.nf.registration.detected.count'=1;;;0; 'sbi.nf.registration.registered.count'=1;;;0;1 'sbi.nf.registration.suspended.count'=0;;;0;1
            ...       3   --warning-sbi-nf-registration-status='%\\{status\\} eq "registered"'     WARNING: SBI registration network function status: registered | 'chf.sessions.active.charging.count'=14;;;0; 'sbi.nf.registration.detected.count'=1;;;0; 'sbi.nf.registration.registered.count'=1;;;0;1 'sbi.nf.registration.suspended.count'=0;;;0;1
            ...       4   --critical-sbi-nf-registration-status='%\\{status\\} eq "registered"'    CRITICAL: SBI registration network function status: registered | 'chf.sessions.active.charging.count'=14;;;0; 'sbi.nf.registration.detected.count'=1;;;0; 'sbi.nf.registration.registered.count'=1;;;0;1 'sbi.nf.registration.suspended.count'=0;;;0;1
            ...       5   --warning-sbi-nf-registration-detected=0                                 WARNING: SBI registration network function detected: 1 | 'chf.sessions.active.charging.count'=14;;;0; 'sbi.nf.registration.detected.count'=1;0:0;;0; 'sbi.nf.registration.registered.count'=1;;;0;1 'sbi.nf.registration.suspended.count'=0;;;0;1
            ...       6   --critical-sbi-nf-registration-detected=0                                CRITICAL: SBI registration network function detected: 1 | 'chf.sessions.active.charging.count'=14;;;0; 'sbi.nf.registration.detected.count'=1;;0:0;0; 'sbi.nf.registration.registered.count'=1;;;0;1 'sbi.nf.registration.suspended.count'=0;;;0;1
            ...       7   --warning-sbi-nf-registration-registered=0                               WARNING: SBI registration network function registered: 1 | 'chf.sessions.active.charging.count'=14;;;0; 'sbi.nf.registration.detected.count'=1;;;0; 'sbi.nf.registration.registered.count'=1;0:0;;0;1 'sbi.nf.registration.suspended.count'=0;;;0;1
            ...       8   --critical-sbi-nf-registration-registered=0                              CRITICAL: SBI registration network function registered: 1 | 'chf.sessions.active.charging.count'=14;;;0; 'sbi.nf.registration.detected.count'=1;;;0; 'sbi.nf.registration.registered.count'=1;;0:0;0;1 'sbi.nf.registration.suspended.count'=0;;;0;1
            ...       9   --warning-sbi-nf-registration-suspended=1:                               WARNING: SBI registration network function suspended: 0 | 'chf.sessions.active.charging.count'=14;;;0; 'sbi.nf.registration.detected.count'=1;;;0; 'sbi.nf.registration.registered.count'=1;;;0;1 'sbi.nf.registration.suspended.count'=0;1:;;0;1
            ...      10   --critical-sbi-nf-registration-suspended=1:                              CRITICAL: SBI registration network function suspended: 0 | 'chf.sessions.active.charging.count'=14;;;0; 'sbi.nf.registration.detected.count'=1;;;0; 'sbi.nf.registration.registered.count'=1;;;0;1 'sbi.nf.registration.suspended.count'=0;;1:;0;1
            ...      11   --warning-sessions-active-charging=0                                     WARNING: Number of active converged charging sessions: 14 | 'chf.sessions.active.charging.count'=14;0:0;;0; 'sbi.nf.registration.detected.count'=1;;;0; 'sbi.nf.registration.registered.count'=1;;;0;1 'sbi.nf.registration.suspended.count'=0;;;0;1
            ...      12   --critical-sessions-active-charging=0                                    CRITICAL: Number of active converged charging sessions: 14 | 'chf.sessions.active.charging.count'=14;;0:0;0; 'sbi.nf.registration.detected.count'=1;;;0; 'sbi.nf.registration.registered.count'=1;;;0;1 'sbi.nf.registration.suspended.count'=0;;;0;1
