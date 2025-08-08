*** Settings ***
Documentation       Check VPN status. VPN-Connection-Status: inactive, active,partiallyActive.

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Test Setup          Ctn Generic Suite Setup
Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown

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
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:        tc    extra_options                                                                                                              expected_result    --
            ...      1     --filter-counters='^total$|^total-normal$'                                                                                 OK: VPN total: 4 - All VPNs are ok | 'total'=4;;;0;
            ...      2     --filter-name='Anonymized 029'                                                                                             CRITICAL: VPN 'Anonymized 029' (Anonymized 157) status: inactive | 'total'=1;;;0; 'total_inactive'=1;;;0; 'total_active'=0;;;0; 'total_partially_active'=0;;;0;
            ...      3     --filter-name='Anonymized 132'                                                                                             OK: VPN total: 1, inactive: 0, active: 1, partially active: 0 - VPN 'Anonymized 132' status: active | 'total'=1;;;0; 'total_inactive'=0;;;0; 'total_active'=1;;;0; 'total_partially_active'=0;;;0;
            ...      4     --filter-vpn-activated='^inactive$'                                                                                        OK: VPN total : skipped (no value(s)), inactive: 0, active: 0, partially active: 0 | 'total_inactive'=0;;;0; 'total_active'=0;;;0; 'total_partially_active'=0;;;0;
            ...      5     --filter-vpn-activated='^active$'                                                                                          CRITICAL: VPN 'Anonymized 029' (Anonymized 157) status: inactive | 'total'=4;;;0; 'total_inactive'=1;;;0; 'total_active'=3;;;0; 'total_partially_active'=0;;;0;
            ...      6     --filter-connection-type='host-to-host'                                                                                    OK: VPN total : skipped (no value(s)), inactive: 0, active: 0, partially active: 0 | 'total_inactive'=0;;;0; 'total_active'=0;;;0; 'total_partially_active'=0;;;0;
            ...      7     --filter-connection-type='site-to-site'                                                                                    CRITICAL: VPN 'Anonymized 029' (Anonymized 157) status: inactive | 'total'=4;;;0; 'total_inactive'=1;;;0; 'total_active'=3;;;0; 'total_partially_active'=0;;;0;
            ...      8     --filter-connection-type='tunnel-interface'                                                                                OK: VPN total : skipped (no value(s)), inactive: 0, active: 0, partially active: 0 | 'total_inactive'=0;;;0; 'total_active'=0;;;0; 'total_partially_active'=0;;;0;
            ...      9     --critical-status='' --warning-status='\\\%{connection_status} ne "active"'                                                WARNING: VPN 'Anonymized 029' (Anonymized 157) status: inactive | 'total'=4;;;0; 'total_inactive'=1;;;0; 'total_active'=3;;;0; 'total_partially_active'=0;;;0;
            ...      10    --critical-status='' --warning-total=0 --critical-total=20                                                                 WARNING: VPN total: 4 | 'total'=4;0:0;0:20;0; 'total_inactive'=1;;;0; 'total_active'=3;;;0; 'total_partially_active'=0;;;0;
            ...      11    --critical-status='' --warning-total-inactive=10 --critical-total-inactive=0                                               CRITICAL: VPN inactive: 1 | 'total'=4;;;0; 'total_inactive'=1;0:10;0:0;0; 'total_active'=3;;;0; 'total_partially_active'=0;;;0;
            ...      12    --critical-status='' --warning-total-active=0 --critical-total-active=0                                                    CRITICAL: VPN active: 3 | 'total'=4;;;0; 'total_inactive'=1;;;0; 'total_active'=3;0:0;0:0;0; 'total_partially_active'=0;;;0;
            ...      13    --critical-status='0' --warning-total-partially-active=1:1                                                                 WARNING: VPN partially active: 0 | 'total'=4;;;0; 'total_inactive'=1;;;0; 'total_active'=3;;;0; 'total_partially_active'=0;1:1;;0;
            ...      14    --critical-status='0' --critical-total-partially-active=1:1                                                                CRITICAL: VPN partially active: 0 | 'total'=4;;;0; 'total_inactive'=1;;;0; 'total_active'=3;;;0; 'total_partially_active'=0;;1:1;0;
            
