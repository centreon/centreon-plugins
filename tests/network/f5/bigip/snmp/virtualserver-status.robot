*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}                                          ${CENTREON_PLUGINS} --plugin=network::f5::bigip::snmp::plugin

*** Test Cases ***
virtualserver-status ${tc}
    [Tags]    network
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=virtualserver-status
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/f5/bigip/snmp/slim-f5-bigip
    ...    ${extra_options}

    Ctn Verify Command Without Connector Output    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                        expected_result    --
            ...      1     ${EMPTY}                                                                             OK: All virtual servers are ok | '/Common/OWA_vs#virtualserver.connections.client.current.count'=0;;;0; '/Common/Ibcm_vs#virtualserver.connections.client.current.count'=22;;;0; '/Common/SAML_vs#virtualserver.connections.client.current.count'=22;;;0; '/Common/Wtop_vs#virtualserver.connections.client.current.count'=0;;;0;
            ...      2     --filter-name='toto'                                                                 UNKNOWN: No entry found.
            ...      3     --warning-status='\\\%{state} eq "enabled"'                                          WARNING: Virtual server '/Common/Ibcm_vs' status: green [state: enabled] [reason: Anonymized 251] - Virtual server '/Common/SAML_vs' status: blue [state: enabled] [reason: Anonymized 107]
            ...      4     --critical-status='\\\%{state} eq "enabled"'                                         CRITICAL: Virtual server '/Common/Ibcm_vs' status: green [state: enabled] [reason: Anonymized 251] - Virtual server '/Common/SAML_vs' status: blue [state: enabled] [reason: Anonymized 107]
            ...      5     --unknown-status='\\\%{state} eq "enabled"'                                          UNKNOWN: Virtual server '/Common/Ibcm_vs' status: green [state: enabled] [reason: Anonymized 251] - Virtual server '/Common/SAML_vs' status: blue [state: enabled] [reason: Anonymized 107]
            ...      6     --warning-current-client-connections=42 --critical-current-client-connections=50     CRITICAL: Virtual server '/Common/ws-prd-ds_vs' current client connections: 111 - Virtual server '/Common/SSO_portail_vs' current client connections: 236