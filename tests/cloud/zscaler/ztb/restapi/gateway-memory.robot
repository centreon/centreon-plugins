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
...                 --mode=gateway-memory
...                 --login-domain=127.0.0.1
...                 --api-domain=127.0.0.1
...                 --client-id=client-id
...                 --client-secret=client-secret
...                 --port=${APIPORT}
...                 --proto=http
...                 --include-gateway-name=LOCATION_501
...                 --timeout=10


*** Test Cases ***
Gateway-memory ${tc}
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
    ...    OK: gateway 'LOCATION_501' memory usage total: 31.30 GB used: 3.58 GB (11.45%) free: 27.72 GB (88.55%) - swap used: 0.00 B | 'gateways.detected.count'=1;;;0; 'LOCATION_501#gateway.memory.usage.bytes'=3847229440B;;;0; 'LOCATION_501#gateway.memory.free.bytes'=29763981312B;;;0; 'LOCATION_501#gateway.memory.usage.percentage'=11.45%;;;0;100 'LOCATION_501#gateway.swap.usage.bytes'=0B;;;0;
    ...    2
    ...    --include-site-name=1
    ...    UNKNOWN: Number of gateways detected: 0 | 'gateways.detected.count'=0;;;0;
    ...    3
    ...    --exclude-site-name=1
    ...    OK: gateway 'LOCATION_501' memory usage total: 31.30 GB used: 3.58 GB (11.45%) free: 27.72 GB (88.55%) - swap used: 0.00 B | 'gateways.detected.count'=1;;;0; 'LOCATION_501#gateway.memory.usage.bytes'=3847229440B;;;0; 'LOCATION_501#gateway.memory.free.bytes'=29763981312B;;;0; 'LOCATION_501#gateway.memory.usage.percentage'=11.45%;;;0;100 'LOCATION_501#gateway.swap.usage.bytes'=0B;;;0;
    ...    4
    ...    --include-cluster-name=1
    ...    UNKNOWN: Number of gateways detected: 0 | 'gateways.detected.count'=0;;;0;
    ...    5
    ...    --exclude-cluster-name=1
    ...    OK: gateway 'LOCATION_501' memory usage total: 31.30 GB used: 3.58 GB (11.45%) free: 27.72 GB (88.55%) - swap used: 0.00 B | 'gateways.detected.count'=1;;;0; 'LOCATION_501#gateway.memory.usage.bytes'=3847229440B;;;0; 'LOCATION_501#gateway.memory.free.bytes'=29763981312B;;;0; 'LOCATION_501#gateway.memory.usage.percentage'=11.45%;;;0;100 'LOCATION_501#gateway.swap.usage.bytes'=0B;;;0;
    ...    6
    ...    --include-gateway-name=1
    ...    OK: All gateways are ok | 'gateways.detected.count'=7;;;0; 'LOCATION_102#gateway.memory.usage.bytes'=3847229440B;;;0; 'LOCATION_102#gateway.memory.free.bytes'=29763981312B;;;0; 'LOCATION_102#gateway.memory.usage.percentage'=11.45%;;;0;100 'LOCATION_102#gateway.swap.usage.bytes'=0B;;;0; 'LOCATION_2-1-gw-02#gateway.memory.usage.bytes'=3847229440B;;;0; 'LOCATION_2-1-gw-02#gateway.memory.free.bytes'=29763981312B;;;0; 'LOCATION_2-1-gw-02#gateway.memory.usage.percentage'=11.45%;;;0;100 'LOCATION_2-1-gw-02#gateway.swap.usage.bytes'=0B;;;0; 'LOCATION_301#gateway.memory.usage.bytes'=3847229440B;;;0; 'LOCATION_301#gateway.memory.free.bytes'=29763981312B;;;0; 'LOCATION_301#gateway.memory.usage.percentage'=11.45%;;;0;100 'LOCATION_301#gateway.swap.usage.bytes'=0B;;;0; 'LOCATION_401#gateway.memory.usage.bytes'=3847229440B;;;0; 'LOCATION_401#gateway.memory.free.bytes'=29763981312B;;;0; 'LOCATION_401#gateway.memory.usage.percentage'=11.45%;;;0;100 'LOCATION_401#gateway.swap.usage.bytes'=0B;;;0; 'LOCATION_501#gateway.memory.usage.bytes'=3847229440B;;;0; 'LOCATION_501#gateway.memory.free.bytes'=29763981312B;;;0; 'LOCATION_501#gateway.memory.usage.percentage'=11.45%;;;0;100 'LOCATION_501#gateway.swap.usage.bytes'=0B;;;0;
    ...    7
    ...    --exclude-gateway-name=1
    ...    UNKNOWN: Number of gateways detected: 0 | 'gateways.detected.count'=0;;;0;
    ...    8
    ...    --include-gateway-id=1
    ...    UNKNOWN: Number of gateways detected: 0 | 'gateways.detected.count'=0;;;0;
    ...    9
    ...    --exclude-gateway-id=1
    ...    OK: gateway 'LOCATION_501' memory usage total: 31.30 GB used: 3.58 GB (11.45%) free: 27.72 GB (88.55%) - swap used: 0.00 B | 'gateways.detected.count'=1;;;0; 'LOCATION_501#gateway.memory.usage.bytes'=3847229440B;;;0; 'LOCATION_501#gateway.memory.free.bytes'=29763981312B;;;0; 'LOCATION_501#gateway.memory.usage.percentage'=11.45%;;;0;100 'LOCATION_501#gateway.swap.usage.bytes'=0B;;;0;
    ...    10
    ...    --custom-perfdata-instances='%(clusterName) %(gatewayName) %(siteName)'
    ...    OK: gateway 'LOCATION_501' memory usage total: 31.30 GB used: 3.58 GB (11.45%) free: 27.72 GB (88.55%) - swap used: 0.00 B | 'gateways.detected.count'=1;;;0; 'LOCATION_5-cluster~LOCATION_501~LOCATION_5#gateway.memory.usage.bytes'=3847229440B;;;0; 'LOCATION_5-cluster~LOCATION_501~LOCATION_5#gateway.memory.free.bytes'=29763981312B;;;0; 'LOCATION_5-cluster~LOCATION_501~LOCATION_5#gateway.memory.usage.percentage'=11.45%;;;0;100 'LOCATION_5-cluster~LOCATION_501~LOCATION_5#gateway.swap.usage.bytes'=0B;;;0;
    ...    11
    ...    --warning-gateways-detected=2:
    ...    WARNING: Number of gateways detected: 1 | 'gateways.detected.count'=1;2:;;0; 'LOCATION_501#gateway.memory.usage.bytes'=3847229440B;;;0; 'LOCATION_501#gateway.memory.free.bytes'=29763981312B;;;0; 'LOCATION_501#gateway.memory.usage.percentage'=11.45%;;;0;100 'LOCATION_501#gateway.swap.usage.bytes'=0B;;;0;
    ...    12
    ...    --critical-gateways-detected=2:
    ...    CRITICAL: Number of gateways detected: 1 | 'gateways.detected.count'=1;;2:;0; 'LOCATION_501#gateway.memory.usage.bytes'=3847229440B;;;0; 'LOCATION_501#gateway.memory.free.bytes'=29763981312B;;;0; 'LOCATION_501#gateway.memory.usage.percentage'=11.45%;;;0;100 'LOCATION_501#gateway.swap.usage.bytes'=0B;;;0;
    ...    13
    ...    --warning-memory-usage=1
    ...    WARNING: gateway 'LOCATION_501' memory usage total: 31.30 GB used: 3.58 GB (11.45%) free: 27.72 GB (88.55%) | 'gateways.detected.count'=1;;;0; 'LOCATION_501#gateway.memory.usage.bytes'=3847229440B;0:1;;0; 'LOCATION_501#gateway.memory.free.bytes'=29763981312B;;;0; 'LOCATION_501#gateway.memory.usage.percentage'=11.45%;;;0;100 'LOCATION_501#gateway.swap.usage.bytes'=0B;;;0;
    ...    14
    ...    --critical-memory-usage=1
    ...    CRITICAL: gateway 'LOCATION_501' memory usage total: 31.30 GB used: 3.58 GB (11.45%) free: 27.72 GB (88.55%) | 'gateways.detected.count'=1;;;0; 'LOCATION_501#gateway.memory.usage.bytes'=3847229440B;;0:1;0; 'LOCATION_501#gateway.memory.free.bytes'=29763981312B;;;0; 'LOCATION_501#gateway.memory.usage.percentage'=11.45%;;;0;100 'LOCATION_501#gateway.swap.usage.bytes'=0B;;;0;
    ...    15
    ...    --warning-memory-usage-free=1
    ...    WARNING: gateway 'LOCATION_501' memory usage total: 31.30 GB used: 3.58 GB (11.45%) free: 27.72 GB (88.55%) | 'gateways.detected.count'=1;;;0; 'LOCATION_501#gateway.memory.usage.bytes'=3847229440B;;;0; 'LOCATION_501#gateway.memory.free.bytes'=29763981312B;0:1;;0; 'LOCATION_501#gateway.memory.usage.percentage'=11.45%;;;0;100 'LOCATION_501#gateway.swap.usage.bytes'=0B;;;0;
    ...    16
    ...    --critical-memory-usage-free=1
    ...    CRITICAL: gateway 'LOCATION_501' memory usage total: 31.30 GB used: 3.58 GB (11.45%) free: 27.72 GB (88.55%) | 'gateways.detected.count'=1;;;0; 'LOCATION_501#gateway.memory.usage.bytes'=3847229440B;;;0; 'LOCATION_501#gateway.memory.free.bytes'=29763981312B;;0:1;0; 'LOCATION_501#gateway.memory.usage.percentage'=11.45%;;;0;100 'LOCATION_501#gateway.swap.usage.bytes'=0B;;;0;
    ...    17
    ...    --warning-memory-usage-prct=1
    ...    WARNING: gateway 'LOCATION_501' memory usage total: 31.30 GB used: 3.58 GB (11.45%) free: 27.72 GB (88.55%) | 'gateways.detected.count'=1;;;0; 'LOCATION_501#gateway.memory.usage.bytes'=3847229440B;;;0; 'LOCATION_501#gateway.memory.free.bytes'=29763981312B;;;0; 'LOCATION_501#gateway.memory.usage.percentage'=11.45%;0:1;;0;100 'LOCATION_501#gateway.swap.usage.bytes'=0B;;;0;
    ...    18
    ...    --critical-memory-usage-prct=1
    ...    CRITICAL: gateway 'LOCATION_501' memory usage total: 31.30 GB used: 3.58 GB (11.45%) free: 27.72 GB (88.55%) | 'gateways.detected.count'=1;;;0; 'LOCATION_501#gateway.memory.usage.bytes'=3847229440B;;;0; 'LOCATION_501#gateway.memory.free.bytes'=29763981312B;;;0; 'LOCATION_501#gateway.memory.usage.percentage'=11.45%;;0:1;0;100 'LOCATION_501#gateway.swap.usage.bytes'=0B;;;0;
    ...    19
    ...    --warning-swap-usage=1:
    ...    WARNING: gateway 'LOCATION_501' swap used: 0.00 B | 'gateways.detected.count'=1;;;0; 'LOCATION_501#gateway.memory.usage.bytes'=3847229440B;;;0; 'LOCATION_501#gateway.memory.free.bytes'=29763981312B;;;0; 'LOCATION_501#gateway.memory.usage.percentage'=11.45%;;;0;100 'LOCATION_501#gateway.swap.usage.bytes'=0B;1:;;0;
    ...    20
    ...    --critical-swap-usage=1:
    ...    CRITICAL: gateway 'LOCATION_501' swap used: 0.00 B | 'gateways.detected.count'=1;;;0; 'LOCATION_501#gateway.memory.usage.bytes'=3847229440B;;;0; 'LOCATION_501#gateway.memory.free.bytes'=29763981312B;;;0; 'LOCATION_501#gateway.memory.usage.percentage'=11.45%;;;0;100 'LOCATION_501#gateway.swap.usage.bytes'=0B;;1:;0;
