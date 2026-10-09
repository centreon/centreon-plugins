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
...                 --mode=gateway-cpu
...                 --login-domain=127.0.0.1
...                 --api-domain=127.0.0.1
...                 --client-id=client-id
...                 --client-secret=client-secret
...                 --port=${APIPORT}
...                 --proto=http
...                 --include-gateway-name=LOCATION_501
...                 --timeout=10


*** Test Cases ***
Gateway-cpu ${tc}
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
    ...    OK: gateway 'LOCATION_501' CPU average usage: 19.96 % | 'gateways.detected.count'=1;;;0; 'LOCATION_501#gateway.cpu.utilization.percentage'=19.96%;;;0;100
    ...    2
    ...    --include-site-name=1
    ...    UNKNOWN: Number of gateways detected: 0 | 'gateways.detected.count'=0;;;0;
    ...    3
    ...    --exclude-site-name=1
    ...    OK: gateway 'LOCATION_501' CPU average usage: 19.96 % | 'gateways.detected.count'=1;;;0; 'LOCATION_501#gateway.cpu.utilization.percentage'=19.96%;;;0;100
    ...    4
    ...    --include-cluster-name=1
    ...    UNKNOWN: Number of gateways detected: 0 | 'gateways.detected.count'=0;;;0;
    ...    5
    ...    --exclude-cluster-name=1
    ...    OK: gateway 'LOCATION_501' CPU average usage: 19.96 % | 'gateways.detected.count'=1;;;0; 'LOCATION_501#gateway.cpu.utilization.percentage'=19.96%;;;0;100
    ...    6
    ...    --include-gateway-name=LOCATION_501
    ...    OK: gateway 'LOCATION_501' CPU average usage: 19.96 % | 'gateways.detected.count'=1;;;0; 'LOCATION_501#gateway.cpu.utilization.percentage'=19.96%;;;0;100
    ...    7
    ...    --exclude-gateway-name=LOCATION_501
    ...    UNKNOWN: Number of gateways detected: 0 | 'gateways.detected.count'=0;;;0;
    ...    8
    ...    --include-gateway-id=1
    ...    UNKNOWN: Number of gateways detected: 0 | 'gateways.detected.count'=0;;;0;
    ...    9
    ...    --exclude-gateway-id=1
    ...    OK: gateway 'LOCATION_501' CPU average usage: 19.96 % | 'gateways.detected.count'=1;;;0; 'LOCATION_501#gateway.cpu.utilization.percentage'=19.96%;;;0;100
    ...    10
    ...    --custom-perfdata-instances='%(siteName) %(clusterName) %(gatewayName)'
    ...    OK: gateway 'LOCATION_501' CPU average usage: 19.96 % | 'gateways.detected.count'=1;;;0; 'LOCATION_5~LOCATION_5-cluster~LOCATION_501#gateway.cpu.utilization.percentage'=19.96%;;;0;100
    ...    11
    ...    --warning-gateways-detected=2:
    ...    WARNING: Number of gateways detected: 1 | 'gateways.detected.count'=1;2:;;0; 'LOCATION_501#gateway.cpu.utilization.percentage'=19.96%;;;0;100
    ...    12
    ...    --critical-gateways-detected=2:
    ...    CRITICAL: Number of gateways detected: 1 | 'gateways.detected.count'=1;;2:;0; 'LOCATION_501#gateway.cpu.utilization.percentage'=19.96%;;;0;100
    ...    13
    ...    --warning-cpu-utilization=1
    ...    WARNING: gateway 'LOCATION_501' CPU average usage: 19.96 % | 'gateways.detected.count'=1;;;0; 'LOCATION_501#gateway.cpu.utilization.percentage'=19.96%;0:1;;0;100
    ...    14
    ...    --critical-cpu-utilization=1
    ...    CRITICAL: gateway 'LOCATION_501' CPU average usage: 19.96 % | 'gateways.detected.count'=1;;;0; 'LOCATION_501#gateway.cpu.utilization.percentage'=19.96%;;0:1;0;100
