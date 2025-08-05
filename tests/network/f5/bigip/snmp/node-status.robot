*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}                                          ${CENTREON_PLUGINS} --plugin=network::f5::bigip::snmp::plugin

*** Test Cases ***
node-status ${tc}
    [Tags]    network
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=node-status
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/f5/bigip/snmp/slim-f5-bigip
    ...    ${extra_options}

    Ctn Verify Command Without Connector Output    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                           expected_result    --
            ...      1     ${EMPTY}                                                                                OK: All nodes are ok | '/Common/delco#node.connections.server.current.count'=0;;;0;
            ...      2     --filter-name='/Common/owa-vip'                                                         OK: Node '/Common/owa-vip' status: blue [state: enabled] [reason: Anonymized 164], current server connections : 0 | '/Common/owa-vip#node.connections.server.current.count'=0;;;0;
            ...      3     --unknown-status='\\\%{state} eq "enabled"'                                             UNKNOWN: Node '/Common/delco' status: blue [state: enabled] [reason: Anonymized 027] - Node '/Common/owa-vip' status: blue [state: enabled] [reason: Anonymized 164]
            ...      4     --critical-status='\\\%{state} eq "enabled"'                                            CRITICAL: Node '/Common/delco' status: blue [state: enabled] [reason: Anonymized 027] - Node '/Common/owa-vip' status: blue [state: enabled] [reason: Anonymized 164]
            ...      5     --warning-status='\\\%{state} eq "enabled"'                                             WARNING: Node '/Common/delco' status: blue [state: enabled] [reason: Anonymized 027] - Node '/Common/owa-vip' status: blue [state: enabled] [reason: Anonymized 164]
            ...      6    --warning-current-server-connections=10 --critical-current-server-connections=5          CRITICAL: Node '/Common/172.20.25.4' current server connections : 59 - Node '/Common/eloi-prod-vs' current server connections : 15 - Node '/Common/ibcm-prd-app1'