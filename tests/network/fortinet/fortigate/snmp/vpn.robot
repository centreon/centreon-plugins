*** Settings ***
Documentation       Check Vdomain statistics and VPN state and traffic.

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}                                          ${CENTREON_PLUGINS} --plugin=network::fortinet::fortigate::snmp::plugin

*** Test Cases ***
vpn ${tc}
    [Tags]    network    vpn
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=vpn
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/fortinet/fortigate/snmp/slim_fortigate-vpn
    ...    --snmp-timeout=10
    ...    --snmp-retries=3
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                                                                            expected_result    --
            ...      1     --filter-vdomain='Anonymized 220'                                                                                                        OK: Virtual domain 'Anonymized 220' Logged users: 0, Active web sessions: 0, Active tunnels: 0, IPSec tunnels state up: 6 - All vpn are ok | 'users'=0users;;;0; 'sessions'=0sessions;;;0; 'active_tunnels'=0tunnels;;;0; 'ipsec_tunnels_count'=6tunnels;;;0;
            ...      2     --warning-status='\\\%{state} eq "up"' --critical-users='@3:3'                                                                           WARNING: Virtual domain 'Anonymized 220' Link 'Anonymized 017' state is 'up' - Link 'Anonymized 027' state is 'up' - Link 'Anonymized 057' state is 'up' - Link 'Anonymized 209' state is 'up' - Link 'Anonymized 217' state is 'up' - Link 'Anonymized 244' state is 'up' | 'users'=0users;;@3:3;0; 'sessions'=0sessions;;;0; 'active_tunnels'=0tunnels;;;0; 'ipsec_tunnels_count'=6tunnels;;;0;
            ...      3     --warning-status='\\\%{state} eq "up"'                                                                                                   WARNING: Virtual domain 'Anonymized 220' Link 'Anonymized 017' state is 'up' - Link 'Anonymized 027' state is 'up' - Link 'Anonymized 057' state is 'up' - Link 'Anonymized 209' state is 'up' - Link 'Anonymized 217' state is 'up' - Link 'Anonymized 244' state is 'up' | 'users'=0users;;;0; 'sessions'=0sessions;;;0; 'active_tunnels'=0tunnels;;;0; 'ipsec_tunnels_count'=6tunnels;;;0; 'traffic_in_Anonymized 017'=0.00b/s;;;0; 'traffic_out_Anonymized 017'=0.00b/s;;;0; 'traffic_in_Anonymized 027'=0.00b/s;;;0; 'traffic_out_Anonymized 027'=0.00b/s;;;0; 'traffic_in_Anonymized 057'=0.00b/s;;;0; 'traffic_out_Anonymized 057'=0.00b/s;;;0; 'traffic_in_Anonymized 209'=0.00b/s;;;0; 'traffic_out_Anonymized 209'=0.00b/s;;;0; 'traffic_in_Anonymized 217'=0.00b/s;;;0; 'traffic_out_Anonymized 217'=0.00b/s;;;0; 'traffic_in_Anonymized 244'=0.00b/s;;;0; 'traffic_out_Anonymized 244'=0.00b/s;;;0;
            ...      4     --critical-status='\\\%{state} eq "up"'                                                                                                  CRITICAL: Virtual domain 'Anonymized 220' Link 'Anonymized 017' state is 'up' - Link 'Anonymized 027' state is 'up' - Link 'Anonymized 057' state is 'up' - Link 'Anonymized 209' state is 'up' - Link 'Anonymized 217' state is 'up' - Link 'Anonymized 244' state is 'up' | 'users'=0users;;;0; 'sessions'=0sessions;;;0; 'active_tunnels'=0tunnels;;;0; 'ipsec_tunnels_count'=6tunnels;;;0; 'traffic_in_Anonymized 017'=0.00b/s;;;0; 'traffic_out_Anonymized 017'=0.00b/s;;;0; 'traffic_in_Anonymized 027'=0.00b/s;;;0; 'traffic_out_Anonymized 027'=0.00b/s;;;0; 'traffic_in_Anonymized 057'=0.00b/s;;;0; 'traffic_out_Anonymized 057'=0.00b/s;;;0; 'traffic_in_Anonymized 209'=0.00b/s;;;0; 'traffic_out_Anonymized 209'=0.00b/s;;;0; 'traffic_in_Anonymized 217'=0.00b/s;;;0; 'traffic_out_Anonymized 217'=0.00b/s;;;0; 'traffic_in_Anonymized 244'=0.00b/s;;;0; 'traffic_out_Anonymized 244'=0.00b/s;;;0;
            ...      5     --filter-vpn='500' --warning-sessions='@0:0' --critical-sessions='@2:2' --use-new-perfdata                                               WARNING: Virtual domain 'Anonymized 220' Active web sessions: 0 | 'Anonymized 220#vpn.users.logged.count'=0users;;;0; 'Anonymized 220#vpn.websessions.active.count'=0sessions;@0:0;@2:2;0; 'Anonymized 220#vpn.tunnels.active.count'=0tunnels;;;0; 'Anonymized 220#vpn.ipsec.tunnels.state.count'=0tunnels;;;0;
            ...      6     ${EMPTY}                                                                                                                                 OK: Virtual domain 'Anonymized 220' Logged users: 0, Active web sessions: 0, Active tunnels: 0, IPSec tunnels state up: 6 - All vpn are ok | 'users'=0users;;;0; 'sessions'=0sessions;;;0; 'active_tunnels'=0tunnels;;;0; 'ipsec_tunnels_count'=6tunnels;;;0; 'traffic_in_Anonymized 017'=0.00b/s;;;0; 'traffic_out_Anonymized 017'=0.00b/s;;;0; 'traffic_in_Anonymized 027'=0.00b/s;;;0; 'traffic_out_Anonymized 027'=0.00b/s;;;0; 'traffic_in_Anonymized 057'=0.00b/s;;;0; 'traffic_out_Anonymized 057'=0.00b/s;;;0; 'traffic_in_Anonymized 209'=0.00b/s;;;0; 'traffic_out_Anonymized 209'=0.00b/s;;;0; 'traffic_in_Anonymized 217'=0.00b/s;;;0; 'traffic_out_Anonymized 217'=0.00b/s;;;0; 'traffic_in_Anonymized 244'=0.00b/s;;;0; 'traffic_out_Anonymized 244'=0.00b/s;;;0;
            ...      7     --warning-ipsec_tunnels_count='@1:1' --critical-ipsec_tunnels_count='@0:0' --use-new-perfdata --filter-vpn='_11'                         CRITICAL: Virtual domain 'Anonymized 220' IPSec tunnels state up: 0 | 'Anonymized 220#vpn.users.logged.count'=0users;;;0; 'Anonymized 220#vpn.websessions.active.count'=0sessions;;;0; 'Anonymized 220#vpn.tunnels.active.count'=0tunnels;;;0; 'Anonymized 220#vpn.ipsec.tunnels.state.count'=0tunnels;@1:1;@0:0;0;