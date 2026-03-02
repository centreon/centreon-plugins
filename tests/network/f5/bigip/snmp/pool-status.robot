*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::f5::bigip::snmp::plugin


*** Test Cases ***
pool-status ${tc}
    [Tags]    network
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=pool-status
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/f5/bigip/snmp/slim-f5-bigip
    ...    ${extra_options}

    Ctn Verify Command Without Connector Output    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                                                                                     expected_result    --
            ...      1     ${EMPTY}                                                                                                                                          OK: All pools are ok | '/Common/IDM_pool#pool.connections.server.current.count'=0;;;0; '/Common/IDM_pool#pool.members.active.count'=0;;;0;
            ...      2     --filter-name='/Common/IDM_pool'                                                                                                                  OK: Pool '/Common/IDM_pool' status: blue [state: enabled] [reason: Anonymized 149] - current server connections: 0, current active members: 0 | '/Common/IDM_pool#pool.connections.server.current.count'=0;;;0; '/Common/IDM_pool#pool.members.active.count'=0;;;0; '/Common/IDM_pool#pool.members.total.count'=1;;;0;
            ...      3     --unknown-status='\\\%{state} eq "enabled"'                                                                                                       UNKNOWN: Pool '/Common/IDM_pool' status: blue [state: enabled] [reason: Anonymized 149] - Pool '/Common/OWA_pool' status: green [state: enabled] [reason: Anonymized 183]
            ...      4     --critical-status='\\\%{state} eq "enabled"'                                                                                                      CRITICAL: Pool '/Common/IDM_pool' status: blue [state: enabled] [reason: Anonymized 149] - Pool '/Common/OWA_pool' status: green [state: enabled] [reason: Anonymized 183]
            ...      5     --warning-status='\\\%{state} eq "enabled"'                                                                                                       WARNING: Pool '/Common/IDM_pool' status: blue [state: enabled] [reason: Anonymized 149] - Pool '/Common/OWA_pool' status: green [state: enabled] [reason: Anonymized 183]
            ...      6     --warning-current-server-connections=10 --critical-current-server-connections=5                                                                   CRITICAL: Pool '/Common/Eloi_pool' current server connections: 10 - Pool '/Common/Portan_pool' current server connections: 6
