*** Settings ***
Documentation       Check VPN status. VPN-Connection-Status: inactive, active,partiallyActive.

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::cyberoam::snmp::plugin


*** Test Cases ***
vpn-status ${tc}
    [Tags]    network    cyberoam
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=vpn-status
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/cyberoam/snmp/slim_sophos
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                                                              expected_result    --
            ...      1     --filter-counters='^total$|^total-normal$'                                                                                  OK: VPN total: 4 - All VPNs are ok | 'total'=4;;;0;
            ...      2     --filter-name='Anonymized 000'                                                                                              OK: VPN total : skipped (no value(s)), inactive: 0, active: 0, partially active: 0 | 'total_inactive'=0;;;0; 'total_active'=0;;;0; 'total_partially_active'=0;;;0;
            ...      3     --filter-vpn-activated='active'                                                                                             CRITICAL: VPN 'Anonymized 029' (Anonymized 157) status: inactive | 'total'=4;;;0; 'total_inactive'=1;;;0; 'total_active'=3;;;0; 'total_partially_active'=0;;;0;  
            ...      4     --filter-connection-mode                                                                                                    CRITICAL: VPN 'Anonymized 029' (Anonymized 157) status: inactive | 'total'=4;;;0; 'total_inactive'=1;;;0; 'total_active'=3;;;0; 'total_partially_active'=0;;;0;
            ...      5     --warning-status='\\\%{connection_status} ne "inactive"'                                                                    CRITICAL: VPN 'Anonymized 029' (Anonymized 157) status: inactive WARNING: VPN 'Anonymized 093' (Anonymized 022) status: active - VPN 'Anonymized 132' status: active - VPN 'Anonymized 252' (Anonymized 070) status: active | 'total'=4;;;0; 'total_inactive'=1;;;0; 'total_active'=3;;;0; 'total_partially_active'=0;;;0;
            ...      6     --critical-status='\\\%{connection_status} =~ /inactive/'                                                                   CRITICAL: VPN 'Anonymized 029' (Anonymized 157) status: inactive | 'total'=4;;;0; 'total_inactive'=1;;;0; 'total_active'=3;;;0; 'total_partially_active'=0;;;0;
            ...      7     --warning-total=0 --critical-total=20                                                                                       CRITICAL: VPN 'Anonymized 029' (Anonymized 157) status: inactive WARNING: VPN total: 4 | 'total'=4;0:0;0:20;0; 'total_inactive'=1;;;0; 'total_active'=3;;;0; 'total_partially_active'=0;;;0;
            ...      8     --warning-total-inactive=10 --critical-total-inactive=0                                                                     CRITICAL: VPN inactive: 1 - VPN 'Anonymized 029' (Anonymized 157) status: inactive | 'total'=4;;;0; 'total_inactive'=1;0:10;0:0;0; 'total_active'=3;;;0; 'total_partially_active'=0;;;0;
            ...      9     --warning-total-active=0 --critical-total-active=0                                                                          CRITICAL: VPN active: 3 - VPN 'Anonymized 029' (Anonymized 157) status: inactive | 'total'=4;;;0; 'total_inactive'=1;;;0; 'total_active'=3;0:0;0:0;0; 'total_partially_active'=0;;;0;