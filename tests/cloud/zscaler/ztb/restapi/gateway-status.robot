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
...                 --mode=gateway-status
...                 --login-domain=127.0.0.1
...                 --api-domain=127.0.0.1
...                 --client-id=client-id
...                 --client-secret=client-secret
...                 --port=${APIPORT}
...                 --proto=http
...                 --include-gateway-name=LOCATION_501
...                 --timeout=10


*** Test Cases ***
Gateway-status ${tc}
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
    ...    OK: gateway 'LOCATION_501' operational state: active [desired state: active], running version: 8.0.8P3a, last update: 8m 9s - health color: green - VRRP state: master | 'gateways.detected.count'=1;;;0; 'LOCATION_501#gateway.update.time.last.seconds'=489s;;;0;
    ...    2
    ...    --include-site-name=1
    ...    UNKNOWN: Number of gateways detected: 0 | 'gateways.detected.count'=0;;;0;
    ...    3
    ...    --exclude-site-name=1
    ...    OK: gateway 'LOCATION_501' operational state: active [desired state: active], running version: 8.0.8P3a, last update: 8m 9s - health color: green - VRRP state: master | 'gateways.detected.count'=1;;;0; 'LOCATION_501#gateway.update.time.last.seconds'=489s;;;0;
    ...    4
    ...    --include-cluster-name=1
    ...    UNKNOWN: Number of gateways detected: 0 | 'gateways.detected.count'=0;;;0;
    ...    5
    ...    --exclude-cluster-name=1
    ...    OK: gateway 'LOCATION_501' operational state: active [desired state: active], running version: 8.0.8P3a, last update: 8m 9s - health color: green - VRRP state: master | 'gateways.detected.count'=1;;;0; 'LOCATION_501#gateway.update.time.last.seconds'=489s;;;0;
    ...    6
    ...    --include-gateway-name=1
    ...    OK: All gateways are ok | 'gateways.detected.count'=7;;;0; 'LOCATION_102#gateway.update.time.last.seconds'=497s;;;0; 'LOCATION_2-1-gw-02#gateway.update.time.last.seconds'=492s;;;0; 'LOCATION_301#gateway.update.time.last.seconds'=490s;;;0; 'LOCATION_401#gateway.update.time.last.seconds'=498s;;;0; 'LOCATION_501#gateway.update.time.last.seconds'=489s;;;0;
    ...    7
    ...    --exclude-gateway-name=1
    ...    UNKNOWN: Number of gateways detected: 0 | 'gateways.detected.count'=0;;;0;
    ...    8
    ...    --include-gateway-id=1
    ...    UNKNOWN: Number of gateways detected: 0 | 'gateways.detected.count'=0;;;0;
    ...    9
    ...    --exclude-gateway-id=1
    ...    OK: gateway 'LOCATION_501' operational state: active [desired state: active], running version: 8.0.8P3a, last update: 8m 9s - health color: green - VRRP state: master | 'gateways.detected.count'=1;;;0; 'LOCATION_501#gateway.update.time.last.seconds'=489s;;;0;
    ...    10
    ...    --custom-perfdata-instances='%(siteName) %(gatewayName) %(clusterName) %(siteName)'
    ...    OK: gateway 'LOCATION_501' operational state: active [desired state: active], running version: 8.0.8P3a, last update: 8m 9s - health color: green - VRRP state: master | 'gateways.detected.count'=1;;;0; 'LOCATION_5~LOCATION_501~LOCATION_5-cluster~LOCATION_5#gateway.update.time.last.seconds'=489s;;;0;
    ...    11
    ...    --warning-gateways-detected=2:
    ...    WARNING: Number of gateways detected: 1 | 'gateways.detected.count'=1;2:;;0; 'LOCATION_501#gateway.update.time.last.seconds'=489s;;;0;
    ...    12
    ...    --critical-gateways-detected=2:
    ...    CRITICAL: Number of gateways detected: 1 | 'gateways.detected.count'=1;;2:;0; 'LOCATION_501#gateway.update.time.last.seconds'=489s;;;0;
    ...    13
    ...    --unknown-gateway-status=1
    ...    UNKNOWN: gateway 'LOCATION_501' operational state: active [desired state: active] | 'gateways.detected.count'=1;;;0; 'LOCATION_501#gateway.update.time.last.seconds'=489s;;;0;
    ...    14
    ...    --warning-gateway-status=1
    ...    WARNING: gateway 'LOCATION_501' operational state: active [desired state: active] | 'gateways.detected.count'=1;;;0; 'LOCATION_501#gateway.update.time.last.seconds'=489s;;;0;
    ...    15
    ...    --critical-gateway-status=1
    ...    CRITICAL: gateway 'LOCATION_501' operational state: active [desired state: active] | 'gateways.detected.count'=1;;;0; 'LOCATION_501#gateway.update.time.last.seconds'=489s;;;0;
    ...    16
    ...    --unknown-running-version=1
    ...    UNKNOWN: gateway 'LOCATION_501' running version: 8.0.8P3a | 'gateways.detected.count'=1;;;0; 'LOCATION_501#gateway.update.time.last.seconds'=489s;;;0;
    ...    17
    ...    --warning-running-version=1
    ...    WARNING: gateway 'LOCATION_501' running version: 8.0.8P3a | 'gateways.detected.count'=1;;;0; 'LOCATION_501#gateway.update.time.last.seconds'=489s;;;0;
    ...    18
    ...    --critical-running-version=1
    ...    CRITICAL: gateway 'LOCATION_501' running version: 8.0.8P3a | 'gateways.detected.count'=1;;;0; 'LOCATION_501#gateway.update.time.last.seconds'=489s;;;0;
    ...    19
    ...    --unknown-gateway-health=1
    ...    UNKNOWN: gateway 'LOCATION_501' health color: green | 'gateways.detected.count'=1;;;0; 'LOCATION_501#gateway.update.time.last.seconds'=489s;;;0;
    ...    20
    ...    --warning-gateway-health=1
    ...    WARNING: gateway 'LOCATION_501' health color: green | 'gateways.detected.count'=1;;;0; 'LOCATION_501#gateway.update.time.last.seconds'=489s;;;0;
    ...    21
    ...    --critical-gateway-health=1
    ...    CRITICAL: gateway 'LOCATION_501' health color: green | 'gateways.detected.count'=1;;;0; 'LOCATION_501#gateway.update.time.last.seconds'=489s;;;0;
    ...    22
    ...    --unknown-gateway-vrrp-status=1
    ...    UNKNOWN: gateway 'LOCATION_501' VRRP state: master | 'gateways.detected.count'=1;;;0; 'LOCATION_501#gateway.update.time.last.seconds'=489s;;;0;
    ...    23
    ...    --warning-gateway-vrrp-status=1
    ...    WARNING: gateway 'LOCATION_501' VRRP state: master | 'gateways.detected.count'=1;;;0; 'LOCATION_501#gateway.update.time.last.seconds'=489s;;;0;
    ...    24
    ...    --critical-gateway-vrrp-status=1
    ...    CRITICAL: gateway 'LOCATION_501' VRRP state: master | 'gateways.detected.count'=1;;;0; 'LOCATION_501#gateway.update.time.last.seconds'=489s;;;0;
    ...    25
    ...    --warning-last-update-time=1
    ...    WARNING: gateway 'LOCATION_501' last update: 8m 9s | 'gateways.detected.count'=1;;;0; 'LOCATION_501#gateway.update.time.last.seconds'=489s;0:1;;0;
    ...    26
    ...    --critical-last-update-time=1
    ...    CRITICAL: gateway 'LOCATION_501' last update: 8m 9s | 'gateways.detected.count'=1;;;0; 'LOCATION_501#gateway.update.time.last.seconds'=489s;;0:1;0;
