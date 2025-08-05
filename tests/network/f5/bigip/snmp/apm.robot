*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}                                          ${CENTREON_PLUGINS} --plugin=network::f5::bigip::snmp::plugin

*** Test Cases ***
apm ${tc}
    [Tags]    network
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=apm
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/f5/bigip/snmp/slim-f5-bigip
    ...    ${extra_options}

    Ctn Verify Command Without Connector Output    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                           expected_result    --
            ...      1     ${EMPTY}                                                                OK: sessions-created : Buffer creation, active sessions: 3724, pending sessions: 146 - All virtual servers are ok
            ...      2     ${EMPTY}                                                                OK: created sessions: 0, active sessions: 3724, pending sessions: 146 - All virtual servers are ok | 'system.sessions.created.count'=0;;;0; 'system.sessions.active.count'=3724;;;0; 'system.sessions.pending.count'=146;;;0;
            ...      3     --filter-ap='toto'                                                      UNKNOWN: No virtual server found.
            ...      4     --warning-sessions-active=3000 --critical-sessions-active=4000          WARNING: active sessions: 3724 | 'system.sessions.created.count'=0;;;0; 'system.sessions.active.count'=3724;0:3000;0:4000;0; 'system.sessions.pending.count'=146;;;0;
            ...      5     --warning-sessions-pending=100 --critical-sessions-pending=140          CRITICAL: pending sessions: 146 | 'system.sessions.created.count'=0;;;0; 'system.sessions.active.count'=3724;;;0; 'system.sessions.pending.count'=146;0:100;0:140;0;