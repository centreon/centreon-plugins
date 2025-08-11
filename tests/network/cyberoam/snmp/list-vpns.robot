*** Settings ***
Documentation       List VPN.

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown

*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::cyberoam::snmp::plugin


*** Test Cases ***
list-vpns ${tc}
    [Tags]    network    cyberoam
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-vpns
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/cyberoam/snmp/slim_sophos
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                                                       expected_result    --
            ...      1     ${EMPTY}                                                                                                           List vpn [oid_path: 1] [name: Anonymized 093] [policy: Anonymized 208] [description: Anonymized 022] [connection_mode: Anonymized 245] [connection_type: site-to-site] [connection_status: active] [activated: active] [oid_path: 2] [name: Anonymized 252] [policy: Anonymized 055] [description: Anonymized 070] [connection_mode: Anonymized 123] [connection_type: site-to-site] [connection_status: active] [activated: active] [oid_path: 3] [name: Anonymized 029] [policy: Anonymized 151] [description: Anonymized 157] [connection_mode: Anonymized 055] [connection_type: site-to-site] [connection_status: inactive] [activated: active] [oid_path: 4] [name: Anonymized 132] [policy: Anonymized 089] [description: ] [connection_mode: Anonymized 185] [connection_type: site-to-site] [connection_status: active] [activated: active]
            ...      2     --filter-name='Anonymized 093'                                                                                      List vpn [oid_path: 1] [name: Anonymized 093] [policy: Anonymized 208] [description: Anonymized 022] [connection_mode: Anonymized 245] [connection_type: site-to-site] [connection_status: active] [activated: active]
            ...      3     --filter-connection-status='inactive'                                                                               List vpn [oid_path: 3] [name: Anonymized 029] [policy: Anonymized 151] [description: Anonymized 157] [connection_mode: Anonymized 055] [connection_type: site-to-site] [connection_status: inactive] [activated: active]
            ...      4     --filter-vpn-activated='active'                                                                                     List vpn [oid_path: 1] [name: Anonymized 093] [policy: Anonymized 208] [description: Anonymized 022] [connection_mode: Anonymized 245] [connection_type: site-to-site] [connection_status: active] [activated: active] [oid_path: 2] [name: Anonymized 252] [policy: Anonymized 055] [description: Anonymized 070] [connection_mode: Anonymized 123] [connection_type: site-to-site] [connection_status: active] [activated: active] [oid_path: 3] [name: Anonymized 029] [policy: Anonymized 151] [description: Anonymized 157] [connection_mode: Anonymized 055] [connection_type: site-to-site] [connection_status: inactive] [activated: active] [oid_path: 4] [name: Anonymized 132] [policy: Anonymized 089] [description: ] [connection_mode: Anonymized 185] [connection_type: site-to-site] [connection_status: active] [activated: active]
