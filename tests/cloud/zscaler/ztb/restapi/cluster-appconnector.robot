*** Settings ***
Documentation       cloud::zscaler::ztb::restapi::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=cloud::zscaler::ztb::restapi::plugin
...                 --mode=cluster-appconnector
...                 --login-domain=127.0.0.1
...                 --api-domain=127.0.0.1
...                 --client-id=client-id
...                 --client-secret=client-secret
...                 --port=${APIPORT}
...                 --proto=http
...                 --timeout=10


*** Test Cases ***
Cluster-appconnector ${tc}
    [Tags]    cloud    zscaler    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: App Connector 'container7' [cluster: LOCATION_5-cluster] status: connected, running on gateways: 2 | 'appconnectors.detected.count'=1;;;0; 'LOCATION_5-cluster~container7#appconnector.running.count'=2;;;0;2
    ...    2
    ...    --include-cluster-name=1
    ...    UNKNOWN: Number of App Connectors detected: 0 | 'appconnectors.detected.count'=0;;;0;
    ...    3
    ...    --exclude-cluster-name=1
    ...    OK: App Connector 'container7' [cluster: LOCATION_5-cluster] status: connected, running on gateways: 2 | 'appconnectors.detected.count'=1;;;0; 'LOCATION_5-cluster~container7#appconnector.running.count'=2;;;0;2
    ...    4
    ...    --include-appconnector-name=1
    ...    UNKNOWN: Number of App Connectors detected: 0 | 'appconnectors.detected.count'=0;;;0;
    ...    5
    ...    --exclude-appconnector-name=1
    ...    OK: App Connector 'container7' [cluster: LOCATION_5-cluster] status: connected, running on gateways: 2 | 'appconnectors.detected.count'=1;;;0; 'LOCATION_5-cluster~container7#appconnector.running.count'=2;;;0;2
    ...    6
    ...    --include-cluster-id=1
    ...    OK: App Connector 'container7' [cluster: LOCATION_5-cluster] status: connected, running on gateways: 2 | 'appconnectors.detected.count'=1;;;0; 'LOCATION_5-cluster~container7#appconnector.running.count'=2;;;0;2
    ...    7
    ...    --exclude-cluster-id=1
    ...    UNKNOWN: Number of App Connectors detected: 0 | 'appconnectors.detected.count'=0;;;0;
    ...    8
    ...    --custom-perfdata-instances='%(appConnectorName) %(clusterName) %(appConnectorName)'
    ...    OK: App Connector 'container7' [cluster: LOCATION_5-cluster] status: connected, running on gateways: 2 | 'appconnectors.detected.count'=1;;;0; 'container7~LOCATION_5-cluster~container7#appconnector.running.count'=2;;;0;2
    ...    9
    ...    --unknown-appconnector-status=1
    ...    UNKNOWN: App Connector 'container7' [cluster: LOCATION_5-cluster] status: connected | 'appconnectors.detected.count'=1;;;0; 'LOCATION_5-cluster~container7#appconnector.running.count'=2;;;0;2
    ...    10
    ...    --warning-appconnector-status=1
    ...    WARNING: App Connector 'container7' [cluster: LOCATION_5-cluster] status: connected | 'appconnectors.detected.count'=1;;;0; 'LOCATION_5-cluster~container7#appconnector.running.count'=2;;;0;2
    ...    11
    ...    --critical-appconnector-status=1
    ...    CRITICAL: App Connector 'container7' [cluster: LOCATION_5-cluster] status: connected | 'appconnectors.detected.count'=1;;;0; 'LOCATION_5-cluster~container7#appconnector.running.count'=2;;;0;2
    ...    12
    ...    --warning-appconnectors-detected=2:
    ...    WARNING: Number of App Connectors detected: 1 | 'appconnectors.detected.count'=1;2:;;0; 'LOCATION_5-cluster~container7#appconnector.running.count'=2;;;0;2
    ...    13
    ...    --critical-appconnectors-detected=2:
    ...    CRITICAL: Number of App Connectors detected: 1 | 'appconnectors.detected.count'=1;;2:;0; 'LOCATION_5-cluster~container7#appconnector.running.count'=2;;;0;2
    ...    14
    ...    --warning-appconnector-running=1
    ...    WARNING: App Connector 'container7' [cluster: LOCATION_5-cluster] running on gateways: 2 | 'appconnectors.detected.count'=1;;;0; 'LOCATION_5-cluster~container7#appconnector.running.count'=2;0:1;;0;2
    ...    15
    ...    --critical-appconnector-running=1
    ...    CRITICAL: App Connector 'container7' [cluster: LOCATION_5-cluster] running on gateways: 2 | 'appconnectors.detected.count'=1;;;0; 'LOCATION_5-cluster~container7#appconnector.running.count'=2;;0:1;0;2
