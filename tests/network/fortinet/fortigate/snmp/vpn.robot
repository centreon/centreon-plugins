*** Settings ***
Documentation       Check Vdomain statistics and VPN state and traffic.

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::fortinet::fortigate::snmp::plugin


*** Test Cases ***
vpn ${tc}
    [Tags]    network    snmp    vpn
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=vpn
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/fortinet/fortigate/snmp/fortigate-vpn
    ...    --snmp-timeout=1
    ...    ${extra_options}

    Ctn Verify Command Without Connector Output    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                                                                                   expected_result    --
            ...      1     ${EMPTY}                                                                                                                                        WARNING: Virtual domain 'Anonymized 220' Link 'VPN2#Anonymized 027' VPN state is 'degraded' (phase2 state is 'down') - Link 'VPN2#Anonymized 244' VPN state is 'degraded' (phase2 state is 'up') | 'users'=0users;;;0; 'sessions'=0sessions;;;0; 'active_tunnels'=0tunnels;;;0; 'ipsec-tunnels-count'=5tunnels;;;0;
            ...      2     --include-vdomain='Anonymized 220'                                                                                                              WARNING: Virtual domain 'Anonymized 220' Link 'VPN2#Anonymized 027' VPN state is 'degraded' (phase2 state is 'down') - Link 'VPN2#Anonymized 244' VPN state is 'degraded' (phase2 state is 'up') | 'users'=0users;;;0; 'sessions'=0sessions;;;0; 'active_tunnels'=0tunnels;;;0; 'ipsec-tunnels-count'=5tunnels;;;0;
            ...      3     --exclude-vdomain='Anonymized 220'                                                                                                              UNKNOWN: No matching VPN found.
            ...      4     --include-vpn-phase1='VPN1'                                                                                                                     OK: Virtual domain 'Anonymized 220' Logged users: 0, Active web sessions: 0, Active tunnels: 0, IPSec tunnels state up: 4 - All vpn are ok | 'users'=0users;;;0; 'sessions'=0sessions;;;0; 'active_tunnels'=0tunnels;;;0; 'ipsec-tunnels-count'=4tunnels;;;0;
            ...      5     --exclude-vpn-phase1='VPN2'                                                                                                                     OK: Virtual domain 'Anonymized 220' Logged users: 0, Active web sessions: 0, Active tunnels: 0, IPSec tunnels state up: 4 - All vpn are ok | 'users'=0users;;;0; 'sessions'=0sessions;;;0; 'active_tunnels'=0tunnels;;;0; 'ipsec-tunnels-count'=4tunnels;;;0;
            ...      6     --include-vpn-phase2='Anonymized 017'                                                                                                           OK: Virtual domain 'Anonymized 220' Logged users: 0, Active web sessions: 0, Active tunnels: 0, IPSec tunnels state up: 1 - Link 'VPN1#Anonymized 017' VPN state is 'up', traffic-in : Buffer creation, traffic-out : Buffer creation | 'users'=0users;;;0; 'sessions'=0sessions;;;0; 'active_tunnels'=0tunnels;;;0; 'ipsec-tunnels-count'=1tunnels;;;0;
            ...      7     --exclude-vpn-phase2='Anonymized 027'                                                                                                           OK: Virtual domain 'Anonymized 220' Logged users: 0, Active web sessions: 0, Active tunnels: 0, IPSec tunnels state up: 5 - All vpn are ok | 'users'=0users;;;0; 'sessions'=0sessions;;;0; 'active_tunnels'=0tunnels;;;0; 'ipsec-tunnels-count'=5tunnels;;;0;
            ...      8     --critical-status='\\\%{state} eq "up"'                                                                                                         CRITICAL: Virtual domain 'Anonymized 220' Link 'VPN1#Anonymized 017' VPN state is 'up' - Link 'VPN1#Anonymized 057' VPN state is 'up' - Link 'VPN1#Anonymized 209' VPN state is 'up' - Link 'VPN1#Anonymized 217' VPN state is 'up' - Link 'VPN2#Anonymized 244' VPN state is 'degraded' (phase2 state is 'up') WARNING: Virtual domain 'Anonymized 220' Link 'VPN2#Anonymized 027' VPN state is 'degraded' (phase2 state is 'down') | 'users'=0users;;;0; 'sessions'=0sessions;;;0; 'active_tunnels'=0tunnels;;;0; 'ipsec-tunnels-count'=5tunnels;;;0; 'traffic_in_VPN1#Anonymized 017'=0.00b/s;;;0; 'traffic_out_VPN1#Anonymized 017'=0.00b/s;;;0; 'traffic_in_VPN1#Anonymized 057'=0.00b/s;;;0; 'traffic_out_VPN1#Anonymized 057'=0.00b/s;;;0; 'traffic_in_VPN1#Anonymized 209'=0.00b/s;;;0; 'traffic_out_VPN1#Anonymized 209'=0.00b/s;;;0; 'traffic_in_VPN1#Anonymized 217'=0.00b/s;;;0; 'traffic_out_VPN1#Anonymized 217'=0.00b/s;;;0; 'traffic_in_VPN2#Anonymized 027'=0.00b/s;;;0; 'traffic_out_VPN2#Anonymized 027'=0.00b/s;;;0; 'traffic_in_VPN2#Anonymized 244'=0.00b/s;;;0; 'traffic_out_VPN2#Anonymized 244'=0.00b/s;;;0;
            ...      9     --include-vpn-phase2='500' --warning-sessions='@0:0' --critical-sessions='@2:2' --use-new-perfdata                                              WARNING: Virtual domain 'Anonymized 220' Active web sessions: 0 | 'Anonymized 220#vpn.users.logged.count'=0users;;;0; 'Anonymized 220#vpn.websessions.active.count'=0sessions;@0:0;@2:2;0; 'Anonymized 220#vpn.tunnels.active.count'=0tunnels;;;0; 'Anonymized 220#vpn.ipsec.tunnels.state.count'=0tunnels;;;0;
            ...      10    --warning-ipsec-tunnels-count='@1:1' --critical-ipsec-tunnels-count='@0:0' --use-new-perfdata --include-vpn-phase2='_11'                        CRITICAL: Virtual domain 'Anonymized 220' IPSec tunnels state up: 0 | 'Anonymized 220#vpn.users.logged.count'=0users;;;0; 'Anonymized 220#vpn.websessions.active.count'=0sessions;;;0; 'Anonymized 220#vpn.tunnels.active.count'=0tunnels;;;0; 'Anonymized 220#vpn.ipsec.tunnels.state.count'=0tunnels;@1:1;@0:0;0;
            ...      11    --critical-traffic-in='@0:0' --critical-traffic-out='@0:0' --use-new-perfdata --include-vpn-phase2='_11' --include-vdomain='Anonymized 220'     OK: Virtual domain 'Anonymized 220' Logged users: 0, Active web sessions: 0, Active tunnels: 0, IPSec tunnels state up: 0 | 'Anonymized 220#vpn.users.logged.count'=0users;;;0; 'Anonymized 220#vpn.websessions.active.count'=0sessions;;;0;
            ...      12     --critical-status='\\\%{vpn_state} eq "degraded"'                                                                                              CRITICAL: Virtual domain 'Anonymized 220' Link 'VPN2#Anonymized 027' VPN state is 'degraded' (phase2 state is 'down') - Link 'VPN2#Anonymized 244' VPN state is 'degraded' (phase2 state is 'up') | 'users'=0users;;;0; 'sessions'=0sessions;;;0; 'active_tunnels'=0tunnels;;;0; 'ipsec-tunnels-count'=5tunnels;;;0; 'traffic_in_VPN1#Anonymized 017'=0.00b/s;;;0; 'traffic_out_VPN1#Anonymized 017'=0.00b/s;;;0; 'traffic_in_VPN1#Anonymized 057'=0.00b/s;;;0; 'traffic_out_VPN1#Anonymized 057'=0.00b/s;;;0; 'traffic_in_VPN1#Anonymized 209'=0.00b/s;;;0; 'traffic_out_VPN1#Anonymized 209'=0.00b/s;;;0; 'traffic_in_VPN1#Anonymized 217'=0.00b/s;;;0; 'traffic_out_VPN1#Anonymized 217'=0.00b/s;;;0; 'traffic_in_VPN2#Anonymized 027'=0.00b/s;;;0; 'traffic_out_VPN2#Anonymized 027'=0.00b/s;;;0; 'traffic_in_VPN2#Anonymized 244'=0.00b/s;;;0; 'traffic_out_VPN2#Anonymized 244'=0.00b/s;;;0;
