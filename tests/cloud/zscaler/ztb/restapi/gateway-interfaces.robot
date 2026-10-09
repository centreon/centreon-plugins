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
...                 --mode=gateway-interfaces
...                 --login-domain=127.0.0.1
...                 --api-domain=127.0.0.1
...                 --client-id=client-id
...                 --client-secret=client-secret
...                 --port=${APIPORT}
...                 --proto=http
...                 --include-gateway-name=LOCATION_102
...                 --include-interface-name=ge5
...                 --timeout=10


*** Test Cases ***
Gateway-interfaces ${tc}
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
    ...    OK: gateway 'LOCATION_102' interface 'ge5' operational state: up [admin state: up], jitter: 2.15 ms, latency: 20.7 ms, loss: 0.04 % | 'gateways.detected.count'=1;;;0; 'LOCATION_102~ge5#gateway.interface.jitter.milliseconds'=2.15ms;;;0; 'LOCATION_102~ge5#gateway.interface.latency.milliseconds'=20.7ms;;;0; 'LOCATION_102~ge5#gateway.interface.loss.percentage'=0.04%;;;0;100
    ...    2
    ...    --include-interface-name=1
    ...    CRITICAL: gateway 'LOCATION_102' interface 'ebond1' operational state: down [admin state: up] - interface 'ge1' operational state: down [admin state: up] - interface 'ge2.10' operational state: down [admin state: up] | 'gateways.detected.count'=1;;;0;
    ...    3
    ...    --exclude-interface-name=1
    ...    OK: gateway 'LOCATION_102' interface 'ge5' operational state: up [admin state: up], jitter: 2.15 ms, latency: 20.7 ms, loss: 0.04 % | 'gateways.detected.count'=1;;;0; 'LOCATION_102~ge5#gateway.interface.jitter.milliseconds'=2.15ms;;;0; 'LOCATION_102~ge5#gateway.interface.latency.milliseconds'=20.7ms;;;0; 'LOCATION_102~ge5#gateway.interface.loss.percentage'=0.04%;;;0;100
    ...    4
    ...    --include-site-name=1
    ...    OK: gateway 'LOCATION_102' interface 'ge5' operational state: up [admin state: up], jitter: 2.15 ms, latency: 20.7 ms, loss: 0.04 % | 'gateways.detected.count'=1;;;0; 'LOCATION_102~ge5#gateway.interface.jitter.milliseconds'=2.15ms;;;0; 'LOCATION_102~ge5#gateway.interface.latency.milliseconds'=20.7ms;;;0; 'LOCATION_102~ge5#gateway.interface.loss.percentage'=0.04%;;;0;100
    ...    5
    ...    --exclude-site-name=1
    ...    UNKNOWN: Number of gateways detected: 0 | 'gateways.detected.count'=0;;;0;
    ...    6
    ...    --include-cluster-name=1
    ...    OK: gateway 'LOCATION_102' interface 'ge5' operational state: up [admin state: up], jitter: 2.15 ms, latency: 20.7 ms, loss: 0.04 % | 'gateways.detected.count'=1;;;0; 'LOCATION_102~ge5#gateway.interface.jitter.milliseconds'=2.15ms;;;0; 'LOCATION_102~ge5#gateway.interface.latency.milliseconds'=20.7ms;;;0; 'LOCATION_102~ge5#gateway.interface.loss.percentage'=0.04%;;;0;100
    ...    7
    ...    --exclude-cluster-name=1
    ...    UNKNOWN: Number of gateways detected: 0 | 'gateways.detected.count'=0;;;0;
    ...    8
    ...    --include-gateway-name=1
    ...    OK: All gateways are ok | 'gateways.detected.count'=7;;;0; 'LOCATION_102~ge5#gateway.interface.jitter.milliseconds'=2.15ms;;;0; 'LOCATION_102~ge5#gateway.interface.latency.milliseconds'=20.7ms;;;0; 'LOCATION_102~ge5#gateway.interface.loss.percentage'=0.04%;;;0;100 'LOCATION_2-1-gw-02~ge5#gateway.interface.jitter.milliseconds'=2.15ms;;;0; 'LOCATION_2-1-gw-02~ge5#gateway.interface.latency.milliseconds'=20.7ms;;;0; 'LOCATION_2-1-gw-02~ge5#gateway.interface.loss.percentage'=0.04%;;;0;100 'LOCATION_301~ge5#gateway.interface.jitter.milliseconds'=2.15ms;;;0; 'LOCATION_301~ge5#gateway.interface.latency.milliseconds'=20.7ms;;;0; 'LOCATION_301~ge5#gateway.interface.loss.percentage'=0.04%;;;0;100 'LOCATION_401~ge5#gateway.interface.jitter.milliseconds'=2.15ms;;;0; 'LOCATION_401~ge5#gateway.interface.latency.milliseconds'=20.7ms;;;0; 'LOCATION_401~ge5#gateway.interface.loss.percentage'=0.04%;;;0;100 'LOCATION_501~ge5#gateway.interface.jitter.milliseconds'=2.15ms;;;0; 'LOCATION_501~ge5#gateway.interface.latency.milliseconds'=20.7ms;;;0; 'LOCATION_501~ge5#gateway.interface.loss.percentage'=0.04%;;;0;100
    ...    9
    ...    --exclude-gateway-name=1
    ...    UNKNOWN: Number of gateways detected: 0 | 'gateways.detected.count'=0;;;0;
    ...    10
    ...    --include-gateway-id=1
    ...    OK: gateway 'LOCATION_102' interface 'ge5' operational state: up [admin state: up], jitter: 2.15 ms, latency: 20.7 ms, loss: 0.04 % | 'gateways.detected.count'=1;;;0; 'LOCATION_102~ge5#gateway.interface.jitter.milliseconds'=2.15ms;;;0; 'LOCATION_102~ge5#gateway.interface.latency.milliseconds'=20.7ms;;;0; 'LOCATION_102~ge5#gateway.interface.loss.percentage'=0.04%;;;0;100
    ...    11
    ...    --exclude-gateway-id=1
    ...    UNKNOWN: Number of gateways detected: 0 | 'gateways.detected.count'=0;;;0;
    ...    12
    ...    --custom-perfdata-instances='%(siteName) %(clusterName) %(gatewayName) %(interfaceName)'
    ...    OK: gateway 'LOCATION_102' interface 'ge5' operational state: up [admin state: up], jitter: 2.15 ms, latency: 20.7 ms, loss: 0.04 % | 'gateways.detected.count'=1;;;0; 'LOCATION_1~LOCATION_1-cluster~LOCATION_102~ge5#gateway.interface.jitter.milliseconds'=2.15ms;;;0; 'LOCATION_1~LOCATION_1-cluster~LOCATION_102~ge5#gateway.interface.latency.milliseconds'=20.7ms;;;0; 'LOCATION_1~LOCATION_1-cluster~LOCATION_102~ge5#gateway.interface.loss.percentage'=0.04%;;;0;100
    ...    13
    ...    --traffic-unit=bps
    ...    OK: gateway 'LOCATION_102' interface 'ge5' operational state: up [admin state: up], jitter: 2.15 ms, latency: 20.7 ms, loss: 0.04 % | 'gateways.detected.count'=1;;;0; 'LOCATION_102~ge5#gateway.interface.jitter.milliseconds'=2.15ms;;;0; 'LOCATION_102~ge5#gateway.interface.latency.milliseconds'=20.7ms;;;0; 'LOCATION_102~ge5#gateway.interface.loss.percentage'=0.04%;;;0;100
    ...    14
    ...    --unknown-interface-status=1
    ...    UNKNOWN: gateway 'LOCATION_102' interface 'ge5' operational state: up [admin state: up] | 'gateways.detected.count'=1;;;0; 'LOCATION_102~ge5#gateway.interface.jitter.milliseconds'=2.15ms;;;0; 'LOCATION_102~ge5#gateway.interface.latency.milliseconds'=20.7ms;;;0; 'LOCATION_102~ge5#gateway.interface.loss.percentage'=0.04%;;;0;100
    ...    15
    ...    --warning-interface-status=1
    ...    WARNING: gateway 'LOCATION_102' interface 'ge5' operational state: up [admin state: up] | 'gateways.detected.count'=1;;;0; 'LOCATION_102~ge5#gateway.interface.jitter.milliseconds'=2.15ms;;;0; 'LOCATION_102~ge5#gateway.interface.latency.milliseconds'=20.7ms;;;0; 'LOCATION_102~ge5#gateway.interface.loss.percentage'=0.04%;;;0;100
    ...    16
    ...    --critical-interface-status=1
    ...    CRITICAL: gateway 'LOCATION_102' interface 'ge5' operational state: up [admin state: up] | 'gateways.detected.count'=1;;;0; 'LOCATION_102~ge5#gateway.interface.jitter.milliseconds'=2.15ms;;;0; 'LOCATION_102~ge5#gateway.interface.latency.milliseconds'=20.7ms;;;0; 'LOCATION_102~ge5#gateway.interface.loss.percentage'=0.04%;;;0;100
    ...    17
    ...    --warning-gateways-detected=2:
    ...    WARNING: Number of gateways detected: 1 | 'gateways.detected.count'=1;2:;;0; 'LOCATION_102~ge5#gateway.interface.jitter.milliseconds'=2.15ms;;;0; 'LOCATION_102~ge5#gateway.interface.latency.milliseconds'=20.7ms;;;0; 'LOCATION_102~ge5#gateway.interface.loss.percentage'=0.04%;;;0;100
    ...    18
    ...    --critical-gateways-detected=2:
    ...    CRITICAL: Number of gateways detected: 1 | 'gateways.detected.count'=1;;2:;0; 'LOCATION_102~ge5#gateway.interface.jitter.milliseconds'=2.15ms;;;0; 'LOCATION_102~ge5#gateway.interface.latency.milliseconds'=20.7ms;;;0; 'LOCATION_102~ge5#gateway.interface.loss.percentage'=0.04%;;;0;100
    ...    19
    ...    --warning-interface-traffic-in=1:
    ...    OK: gateway 'LOCATION_102' interface 'ge5' operational state: up [admin state: up], jitter: 2.15 ms, latency: 20.7 ms, loss: 0.04 % | 'gateways.detected.count'=1;;;0; 'LOCATION_102~ge5#gateway.interface.jitter.milliseconds'=2.15ms;;;0; 'LOCATION_102~ge5#gateway.interface.latency.milliseconds'=20.7ms;;;0; 'LOCATION_102~ge5#gateway.interface.loss.percentage'=0.04%;;;0;100
    ...    20
    ...    --critical-interface-traffic-in=1:
    ...    OK: gateway 'LOCATION_102' interface 'ge5' operational state: up [admin state: up], jitter: 2.15 ms, latency: 20.7 ms, loss: 0.04 % | 'gateways.detected.count'=1;;;0; 'LOCATION_102~ge5#gateway.interface.jitter.milliseconds'=2.15ms;;;0; 'LOCATION_102~ge5#gateway.interface.latency.milliseconds'=20.7ms;;;0; 'LOCATION_102~ge5#gateway.interface.loss.percentage'=0.04%;;;0;100
    ...    21
    ...    --warning-interface-traffic-out=1:
    ...    OK: gateway 'LOCATION_102' interface 'ge5' operational state: up [admin state: up], jitter: 2.15 ms, latency: 20.7 ms, loss: 0.04 % | 'gateways.detected.count'=1;;;0; 'LOCATION_102~ge5#gateway.interface.jitter.milliseconds'=2.15ms;;;0; 'LOCATION_102~ge5#gateway.interface.latency.milliseconds'=20.7ms;;;0; 'LOCATION_102~ge5#gateway.interface.loss.percentage'=0.04%;;;0;100
    ...    22
    ...    --critical-interface-traffic-out=1:
    ...    OK: gateway 'LOCATION_102' interface 'ge5' operational state: up [admin state: up], jitter: 2.15 ms, latency: 20.7 ms, loss: 0.04 % | 'gateways.detected.count'=1;;;0; 'LOCATION_102~ge5#gateway.interface.jitter.milliseconds'=2.15ms;;;0; 'LOCATION_102~ge5#gateway.interface.latency.milliseconds'=20.7ms;;;0; 'LOCATION_102~ge5#gateway.interface.loss.percentage'=0.04%;;;0;100
    ...    23
    ...    --warning-interface-jitter=1
    ...    WARNING: gateway 'LOCATION_102' interface 'ge5' jitter: 2.15 ms | 'gateways.detected.count'=1;;;0; 'LOCATION_102~ge5#gateway.interface.jitter.milliseconds'=2.15ms;0:1;;0; 'LOCATION_102~ge5#gateway.interface.latency.milliseconds'=20.7ms;;;0; 'LOCATION_102~ge5#gateway.interface.loss.percentage'=0.04%;;;0;100
    ...    24
    ...    --critical-interface-jitter=1
    ...    CRITICAL: gateway 'LOCATION_102' interface 'ge5' jitter: 2.15 ms | 'gateways.detected.count'=1;;;0; 'LOCATION_102~ge5#gateway.interface.jitter.milliseconds'=2.15ms;;0:1;0; 'LOCATION_102~ge5#gateway.interface.latency.milliseconds'=20.7ms;;;0; 'LOCATION_102~ge5#gateway.interface.loss.percentage'=0.04%;;;0;100
    ...    25
    ...    --warning-interface-latency=1
    ...    WARNING: gateway 'LOCATION_102' interface 'ge5' latency: 20.7 ms | 'gateways.detected.count'=1;;;0; 'LOCATION_102~ge5#gateway.interface.jitter.milliseconds'=2.15ms;;;0; 'LOCATION_102~ge5#gateway.interface.latency.milliseconds'=20.7ms;0:1;;0; 'LOCATION_102~ge5#gateway.interface.loss.percentage'=0.04%;;;0;100
    ...    26
    ...    --critical-interface-latency=1
    ...    CRITICAL: gateway 'LOCATION_102' interface 'ge5' latency: 20.7 ms | 'gateways.detected.count'=1;;;0; 'LOCATION_102~ge5#gateway.interface.jitter.milliseconds'=2.15ms;;;0; 'LOCATION_102~ge5#gateway.interface.latency.milliseconds'=20.7ms;;0:1;0; 'LOCATION_102~ge5#gateway.interface.loss.percentage'=0.04%;;;0;100
    ...    27
    ...    --warning-interface-loss=1:
    ...    WARNING: gateway 'LOCATION_102' interface 'ge5' loss: 0.04 % | 'gateways.detected.count'=1;;;0; 'LOCATION_102~ge5#gateway.interface.jitter.milliseconds'=2.15ms;;;0; 'LOCATION_102~ge5#gateway.interface.latency.milliseconds'=20.7ms;;;0; 'LOCATION_102~ge5#gateway.interface.loss.percentage'=0.04%;1:;;0;100
    ...    28
    ...    --critical-interface-loss=1:
    ...    CRITICAL: gateway 'LOCATION_102' interface 'ge5' loss: 0.04 % | 'gateways.detected.count'=1;;;0; 'LOCATION_102~ge5#gateway.interface.jitter.milliseconds'=2.15ms;;;0; 'LOCATION_102~ge5#gateway.interface.latency.milliseconds'=20.7ms;;;0; 'LOCATION_102~ge5#gateway.interface.loss.percentage'=0.04%;;1:;0;100
