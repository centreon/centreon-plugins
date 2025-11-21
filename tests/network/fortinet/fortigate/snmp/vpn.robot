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

    Examples:        tc    extra_options                                                                                                                            expected_result    --
            ...      1     ${EMPTY}                                                                                                                                 OK: Virtual domain 'Anonymized 220' Logged users: 0, Active web sessions: 0, Active tunnels: 0, IPSec tunnels state up: 6 - All vpn are ok | 'users'=0users;;;0; 'sessions'=0sessions;;;0; 'active_tunnels'=0tunnels;;;0; 'ipsec-tunnels-count'=6tunnels;;;0;
            ...      2     --filter-vdomain='Anonymized 220'                                                                                                        OK: Virtual domain 'Anonymized 220' Logged users: 0, Active web sessions: 0, Active tunnels: 0, IPSec tunnels state up: 6 - All vpn are ok | 'users'=0users;;;0; 'sessions'=0sessions;;;0; 'active_tunnels'=0tunnels;;;0; 'ipsec-tunnels-count'=6tunnels;;;0;
            ...      3     --warning-status='\\\%{state} eq "up"'                                                                                                   WARNING: Virtual domain 'Anonymized 220' Link 'Anonymized 017' state is 'up' - Link 'Anonymized 027' state is 'up' - Link 'Anonymized 057' state is 'up'
            ...      4     --critical-status='\\\%{state} eq "up"'                                                                                                  CRITICAL: Virtual domain 'Anonymized 220' Link 'Anonymized 017' state is 'up' - Link 'Anonymized 027' state is 'up' - Link 'Anonymized 057' state is 'up'
            ...      5     --filter-vpn='500' --warning-sessions='@0:0' --critical-sessions='@2:2' --use-new-perfdata                                               WARNING: Virtual domain 'Anonymized 220' Active web sessions: 0 | 'Anonymized 220#vpn.users.logged.count'=0users;;;0; 'Anonymized 220#vpn.websessions.active.count'=0sessions;@0:0;@2:2;0; 'Anonymized 220#vpn.tunnels.active.count'=0tunnels;;;0; 'Anonymized 220#vpn.ipsec.tunnels.state.count'=0tunnels;;;0;
            ...      6     --warning-ipsec-tunnels-count='@1:1' --critical-ipsec-tunnels-count='@0:0' --use-new-perfdata --filter-vpn='_11'                         CRITICAL: Virtual domain 'Anonymized 220' IPSec tunnels state up: 0 | 'Anonymized 220#vpn.users.logged.count'=0users;;;0; 'Anonymized 220#vpn.websessions.active.count'=0sessions;;;0; 'Anonymized 220#vpn.tunnels.active.count'=0tunnels;;;0; 'Anonymized 220#vpn.ipsec.tunnels.state.count'=0tunnels;@1:1;@0:0;0;
            ...      7     --critical-traffic-in='@0:0' --critical-traffic-out='@0:0' --use-new-perfdata --filter-vpn='_11' --filter-vdomain='Anonymized 220'       OK: Virtual domain 'Anonymized 220' Logged users: 0, Active web sessions: 0, Active tunnels: 0, IPSec tunnels state up: 0 | 'Anonymized 220#vpn.users.logged.count'=0users;;;0; 'Anonymized 220#vpn.websessions.active.count'=0sessions;;;0;
