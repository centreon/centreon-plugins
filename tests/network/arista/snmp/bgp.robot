*** Settings ***
Documentation       Check Arista usging BGP

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}              ${CENTREON_PLUGINS} --plugin=network::arista::snmp::plugin

*** Test Cases ***
bgp ${tc}
    [Tags]    network    arista    snmp    bgp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=bgp
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/arista/snmp/arista-bgp
    ...    ${extra_options}

    Ctn Verify Command Without Connector Output    ${command}    ${expected_result}

    Examples:     tc    extra_options                                                 expected_result    --
    ...           1     ${EMPTY}                                                      CRITICAL: Peer [description: Test IPV6, localAddr: [2001:db8::1]:34022, localAs: 65022, remoteAddr: [2001:db8::2]:12555, remoteAs: 65444] state: connect [admin status: running] | 'bgp.peers.detected.count'=3;;;0;
    ...           2     --include-local-as=65011                                      OK: number of peers detected: 1 - Peer [description: Test 2, localAddr: 192.168.170.10:34011, localAs: 65011, remoteAddr: 192.168.1.10:12111, remoteAs: 65111] state: idle [admin status: halted] | 'bgp.peers.detected.count'=1;;;0;
    ...           3     --exclude-local-as=65022                                      OK: number of peers detected: 2 - All BGP peers are ok | 'bgp.peers.detected.count'=2;;;0;
    ...           4     --include-remote-as=99999                                     UNKNOWN: number of peers detected: 0 | 'bgp.peers.detected.count'=0;;;0;
    ...           5     --exclude-remote-as=65444                                     OK: number of peers detected: 2 - All BGP peers are ok | 'bgp.peers.detected.count'=2;;;0;
    ...           6     --include-description='Test 1'                                OK: number of peers detected: 1 - Peer [description: Test 1, localAddr: 11.11.11.11:34001, localAs: 65001, remoteAddr: 10.10.10.10:12101, remoteAs: 65101] state: established [admin status: running] | 'bgp.peers.detected.count'=1;;;0;
    ...           7     --exclude-description='IPV6'                                  OK: number of peers detected: 2 - All BGP peers are ok | 'bgp.peers.detected.count'=2;;;0;
    ...           8     --include-local-addr='192\.168'                               OK: number of peers detected: 1 - Peer [description: Test 2, localAddr:
    ...           9     --exclude-local-addr='2001:db8'                               OK: number of peers detected: 2 - All BGP peers are ok | 'bgp.peers.detected.count'=2;;;0;
    ...           10    --include-remote-addr='10\.10'                                OK: number of peers detected: 1 - Peer [description: Test 1, localAddr: 11.11.11.11:34001, localAs: 65001, remoteAddr: 10.10.10.10:12101, remoteAs: 65101] state: established [admin status: running] | 'bgp.peers.detected.count'=1;;;0;
    ...           11    --exclude-remote-addr='2001:db8'                              OK: number of peers detected: 2 - All BGP peers are ok | 'bgp.peers.detected.count'=2;;;0;
    ...           12    --critical-status='' --warning-status='\\\%{state} =~ /established/'       WARNING: Peer [description: Test 1, localAddr: 11.11.11.11:34001, localAs: 65001, remoteAddr: 10.10.10.10:12101, remoteAs: 65101] state: established [admin status: running] | 'bgp.peers.detected.count'=3;;;0;
    ...           13    --critical-status='' --critical-peers-detected='4:'           CRITICAL: number of peers detected: 3 | 'bgp.peers.detected.count'=3;;4:;0;
    ...           14    --critical-status='' --warning-peers-detected='4:'            WARNING: number of peers detected: 3 | 'bgp.peers.detected.count'=3;4:;;0;
