*** Settings ***
Documentation       cloud::zscaler::ztb::restapi::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${INJECT_PERL}      -Mfixed_date -I${CURDIR}
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=cloud::zscaler::ztb::restapi::plugin
...                 --mode=cluster-ipsec
...                 --login-domain=127.0.0.1
...                 --api-domain=127.0.0.1
...                 --client-id=client-id
...                 --client-secret=client-secret
...                 --port=${APIPORT}
...                 --proto=http
...                 --timeout=10


*** Test Cases ***
Cluster-ipsec ${tc}
    [Tags]    cloud    zscaler    restapi

    ${OLD_PERL5OPT}=    Get Environment Variable    PERL5OPT    default=
    Set Environment Variable    PERL5OPT    ${INJECT_PERL} ${OLD_PERL5OPT}

    ${command}=    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Strings    ${command}    ${expected_result}

    Set Environment Variable    PERL5OPT    ${OLD_PERL5OPT}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: All IPsec tunnels are ok | 'tunnels.ipsec.detected.count'=6;;;0; 'LOCATION_2-1-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=495s;;;0; 'LOCATION_1-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=493s;;;0; 'LOCATION_4-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=498s;;;0; 'LOCATION_5-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=500s;;;0; 'LOCATION_5-cluster~zia-tunnel1#tunnel.ipsec.refresh.time.last.seconds'=500s;;;0; 'LOCATION_3-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=504s;;;0;
    ...    2
    ...    --include-cluster-name=1
    ...    OK: All IPsec tunnels are ok | 'tunnels.ipsec.detected.count'=2;;;0; 'LOCATION_2-1-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=495s;;;0; 'LOCATION_1-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=493s;;;0;
    ...    3
    ...    --exclude-cluster-name=1
    ...    OK: All IPsec tunnels are ok | 'tunnels.ipsec.detected.count'=4;;;0; 'LOCATION_4-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=498s;;;0; 'LOCATION_5-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=500s;;;0; 'LOCATION_5-cluster~zia-tunnel1#tunnel.ipsec.refresh.time.last.seconds'=500s;;;0; 'LOCATION_3-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=504s;;;0;
    ...    4
    ...    --include-tunnel-name=1
    ...    OK: tunnel 'zia-tunnel1' [cluster: LOCATION_5-cluster] IKE status: established, SA status: established, last refresh: 8m 20s | 'tunnels.ipsec.detected.count'=1;;;0; 'LOCATION_5-cluster~zia-tunnel1#tunnel.ipsec.refresh.time.last.seconds'=500s;;;0;
    ...    5
    ...    --exclude-tunnel-name=1
    ...    OK: All IPsec tunnels are ok | 'tunnels.ipsec.detected.count'=5;;;0; 'LOCATION_2-1-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=495s;;;0; 'LOCATION_1-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=493s;;;0; 'LOCATION_4-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=498s;;;0; 'LOCATION_5-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=500s;;;0; 'LOCATION_3-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=504s;;;0;
    ...    6
    ...    --include-cluster-id=1
    ...    OK: All IPsec tunnels are ok | 'tunnels.ipsec.detected.count'=3;;;0; 'LOCATION_2-1-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=495s;;;0; 'LOCATION_5-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=500s;;;0; 'LOCATION_5-cluster~zia-tunnel1#tunnel.ipsec.refresh.time.last.seconds'=500s;;;0;
    ...    7
    ...    --exclude-cluster-id=1
    ...    OK: All IPsec tunnels are ok | 'tunnels.ipsec.detected.count'=3;;;0; 'LOCATION_1-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=493s;;;0; 'LOCATION_4-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=498s;;;0; 'LOCATION_3-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=504s;;;0;
    ...    8
    ...    --custom-perfdata-instances='%(clusterName) %(tunnelName) %(clusterName)'
    ...    OK: All IPsec tunnels are ok | 'tunnels.ipsec.detected.count'=6;;;0; 'LOCATION_2-1-cluster~zia-tunnel0~LOCATION_2-1-cluster#tunnel.ipsec.refresh.time.last.seconds'=495s;;;0; 'LOCATION_1-cluster~zia-tunnel0~LOCATION_1-cluster#tunnel.ipsec.refresh.time.last.seconds'=493s;;;0; 'LOCATION_4-cluster~zia-tunnel0~LOCATION_4-cluster#tunnel.ipsec.refresh.time.last.seconds'=498s;;;0; 'LOCATION_5-cluster~zia-tunnel0~LOCATION_5-cluster#tunnel.ipsec.refresh.time.last.seconds'=500s;;;0; 'LOCATION_5-cluster~zia-tunnel1~LOCATION_5-cluster#tunnel.ipsec.refresh.time.last.seconds'=500s;;;0; 'LOCATION_3-cluster~zia-tunnel0~LOCATION_3-cluster#tunnel.ipsec.refresh.time.last.seconds'=504s;;;0;
    ...    9
    ...    --unknown-sa-status='${PERCENT}\\{saStatus\\} == "established"'
    ...    UNKNOWN: tunnel 'zia-tunnel0' [cluster: LOCATION_2-1-cluster] SA status: established - tunnel 'zia-tunnel0' [cluster: LOCATION_1-cluster] SA status: established - tunnel 'zia-tunnel0' [cluster: LOCATION_4-cluster] SA status: established - tunnel 'zia-tunnel0' [cluster: LOCATION_5-cluster] SA status: established - tunnel 'zia-tunnel1' [cluster: LOCATION_5-cluster] SA status: established - tunnel 'zia-tunnel0' [cluster: LOCATION_3-cluster] SA status: established | 'tunnels.ipsec.detected.count'=6;;;0; 'LOCATION_2-1-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=495s;;;0; 'LOCATION_1-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=493s;;;0; 'LOCATION_4-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=498s;;;0; 'LOCATION_5-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=500s;;;0; 'LOCATION_5-cluster~zia-tunnel1#tunnel.ipsec.refresh.time.last.seconds'=500s;;;0; 'LOCATION_3-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=504s;;;0;
    ...    10
    ...    --warning-sa-status='${PERCENT}\\{saStatus\\} == "established"'
    ...    WARNING: tunnel 'zia-tunnel0' [cluster: LOCATION_2-1-cluster] SA status: established - tunnel 'zia-tunnel0' [cluster: LOCATION_1-cluster] SA status: established - tunnel 'zia-tunnel0' [cluster: LOCATION_4-cluster] SA status: established - tunnel 'zia-tunnel0' [cluster: LOCATION_5-cluster] SA status: established - tunnel 'zia-tunnel1' [cluster: LOCATION_5-cluster] SA status: established - tunnel 'zia-tunnel0' [cluster: LOCATION_3-cluster] SA status: established | 'tunnels.ipsec.detected.count'=6;;;0; 'LOCATION_2-1-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=495s;;;0; 'LOCATION_1-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=493s;;;0; 'LOCATION_4-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=498s;;;0; 'LOCATION_5-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=500s;;;0; 'LOCATION_5-cluster~zia-tunnel1#tunnel.ipsec.refresh.time.last.seconds'=500s;;;0; 'LOCATION_3-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=504s;;;0;
    ...    11
    ...    --critical-sa-status='${PERCENT}\\{saStatus\\} == "established"'
    ...    CRITICAL: tunnel 'zia-tunnel0' [cluster: LOCATION_2-1-cluster] SA status: established - tunnel 'zia-tunnel0' [cluster: LOCATION_1-cluster] SA status: established - tunnel 'zia-tunnel0' [cluster: LOCATION_4-cluster] SA status: established - tunnel 'zia-tunnel0' [cluster: LOCATION_5-cluster] SA status: established - tunnel 'zia-tunnel1' [cluster: LOCATION_5-cluster] SA status: established - tunnel 'zia-tunnel0' [cluster: LOCATION_3-cluster] SA status: established | 'tunnels.ipsec.detected.count'=6;;;0; 'LOCATION_2-1-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=495s;;;0; 'LOCATION_1-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=493s;;;0; 'LOCATION_4-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=498s;;;0; 'LOCATION_5-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=500s;;;0; 'LOCATION_5-cluster~zia-tunnel1#tunnel.ipsec.refresh.time.last.seconds'=500s;;;0; 'LOCATION_3-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=504s;;;0;
    ...    12
    ...    --unknown-ike-status='${PERCENT}\\{ikeStatus\\} == "established"'
    ...    UNKNOWN: tunnel 'zia-tunnel0' [cluster: LOCATION_2-1-cluster] IKE status: established - tunnel 'zia-tunnel0' [cluster: LOCATION_1-cluster] IKE status: established - tunnel 'zia-tunnel0' [cluster: LOCATION_4-cluster] IKE status: established - tunnel 'zia-tunnel0' [cluster: LOCATION_5-cluster] IKE status: established - tunnel 'zia-tunnel1' [cluster: LOCATION_5-cluster] IKE status: established - tunnel 'zia-tunnel0' [cluster: LOCATION_3-cluster] IKE status: established | 'tunnels.ipsec.detected.count'=6;;;0; 'LOCATION_2-1-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=495s;;;0; 'LOCATION_1-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=493s;;;0; 'LOCATION_4-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=498s;;;0; 'LOCATION_5-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=500s;;;0; 'LOCATION_5-cluster~zia-tunnel1#tunnel.ipsec.refresh.time.last.seconds'=500s;;;0; 'LOCATION_3-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=504s;;;0;
    ...    13
    ...    --warning-ike-status='${PERCENT}\\{ikeStatus\\} == "established"'
    ...    WARNING: tunnel 'zia-tunnel0' [cluster: LOCATION_2-1-cluster] IKE status: established - tunnel 'zia-tunnel0' [cluster: LOCATION_1-cluster] IKE status: established - tunnel 'zia-tunnel0' [cluster: LOCATION_4-cluster] IKE status: established - tunnel 'zia-tunnel0' [cluster: LOCATION_5-cluster] IKE status: established - tunnel 'zia-tunnel1' [cluster: LOCATION_5-cluster] IKE status: established - tunnel 'zia-tunnel0' [cluster: LOCATION_3-cluster] IKE status: established | 'tunnels.ipsec.detected.count'=6;;;0; 'LOCATION_2-1-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=495s;;;0; 'LOCATION_1-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=493s;;;0; 'LOCATION_4-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=498s;;;0; 'LOCATION_5-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=500s;;;0; 'LOCATION_5-cluster~zia-tunnel1#tunnel.ipsec.refresh.time.last.seconds'=500s;;;0; 'LOCATION_3-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=504s;;;0;
    ...    14
    ...    --critical-ike-status='${PERCENT}\\{ikeStatus\\} == "established"'
    ...    CRITICAL: tunnel 'zia-tunnel0' [cluster: LOCATION_2-1-cluster] IKE status: established - tunnel 'zia-tunnel0' [cluster: LOCATION_1-cluster] IKE status: established - tunnel 'zia-tunnel0' [cluster: LOCATION_4-cluster] IKE status: established - tunnel 'zia-tunnel0' [cluster: LOCATION_5-cluster] IKE status: established - tunnel 'zia-tunnel1' [cluster: LOCATION_5-cluster] IKE status: established - tunnel 'zia-tunnel0' [cluster: LOCATION_3-cluster] IKE status: established | 'tunnels.ipsec.detected.count'=6;;;0; 'LOCATION_2-1-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=495s;;;0; 'LOCATION_1-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=493s;;;0; 'LOCATION_4-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=498s;;;0; 'LOCATION_5-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=500s;;;0; 'LOCATION_5-cluster~zia-tunnel1#tunnel.ipsec.refresh.time.last.seconds'=500s;;;0; 'LOCATION_3-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=504s;;;0;
    ...    15
    ...    --warning-tunnels-ipsec-detected=1
    ...    WARNING: Number of IPsec tunnels detected: 6 | 'tunnels.ipsec.detected.count'=6;0:1;;0; 'LOCATION_2-1-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=495s;;;0; 'LOCATION_1-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=493s;;;0; 'LOCATION_4-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=498s;;;0; 'LOCATION_5-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=500s;;;0; 'LOCATION_5-cluster~zia-tunnel1#tunnel.ipsec.refresh.time.last.seconds'=500s;;;0; 'LOCATION_3-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=504s;;;0;
    ...    16
    ...    --critical-tunnels-ipsec-detected=1
    ...    CRITICAL: Number of IPsec tunnels detected: 6 | 'tunnels.ipsec.detected.count'=6;;0:1;0; 'LOCATION_2-1-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=495s;;;0; 'LOCATION_1-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=493s;;;0; 'LOCATION_4-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=498s;;;0; 'LOCATION_5-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=500s;;;0; 'LOCATION_5-cluster~zia-tunnel1#tunnel.ipsec.refresh.time.last.seconds'=500s;;;0; 'LOCATION_3-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=504s;;;0;
    ...    17
    ...    --warning-last-refresh-time=1
    ...    WARNING: tunnel 'zia-tunnel0' [cluster: LOCATION_2-1-cluster] last refresh: 8m 15s - tunnel 'zia-tunnel0' [cluster: LOCATION_1-cluster] last refresh: 8m 13s - tunnel 'zia-tunnel0' [cluster: LOCATION_4-cluster] last refresh: 8m 18s - tunnel 'zia-tunnel0' [cluster: LOCATION_5-cluster] last refresh: 8m 20s - tunnel 'zia-tunnel1' [cluster: LOCATION_5-cluster] last refresh: 8m 20s - tunnel 'zia-tunnel0' [cluster: LOCATION_3-cluster] last refresh: 8m 24s | 'tunnels.ipsec.detected.count'=6;;;0; 'LOCATION_2-1-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=495s;0:1;;0; 'LOCATION_1-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=493s;0:1;;0; 'LOCATION_4-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=498s;0:1;;0; 'LOCATION_5-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=500s;0:1;;0; 'LOCATION_5-cluster~zia-tunnel1#tunnel.ipsec.refresh.time.last.seconds'=500s;0:1;;0; 'LOCATION_3-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=504s;0:1;;0;
    ...    18
    ...    --critical-last-refresh-time=1
    ...    CRITICAL: tunnel 'zia-tunnel0' [cluster: LOCATION_2-1-cluster] last refresh: 8m 15s - tunnel 'zia-tunnel0' [cluster: LOCATION_1-cluster] last refresh: 8m 13s - tunnel 'zia-tunnel0' [cluster: LOCATION_4-cluster] last refresh: 8m 18s - tunnel 'zia-tunnel0' [cluster: LOCATION_5-cluster] last refresh: 8m 20s - tunnel 'zia-tunnel1' [cluster: LOCATION_5-cluster] last refresh: 8m 20s - tunnel 'zia-tunnel0' [cluster: LOCATION_3-cluster] last refresh: 8m 24s | 'tunnels.ipsec.detected.count'=6;;;0; 'LOCATION_2-1-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=495s;;0:1;0; 'LOCATION_1-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=493s;;0:1;0; 'LOCATION_4-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=498s;;0:1;0; 'LOCATION_5-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=500s;;0:1;0; 'LOCATION_5-cluster~zia-tunnel1#tunnel.ipsec.refresh.time.last.seconds'=500s;;0:1;0; 'LOCATION_3-cluster~zia-tunnel0#tunnel.ipsec.refresh.time.last.seconds'=504s;;0:1;0;
