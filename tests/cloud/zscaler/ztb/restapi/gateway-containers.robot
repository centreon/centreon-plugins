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
...                 --mode=gateway-containers
...                 --login-domain=127.0.0.1
...                 --api-domain=127.0.0.1
...                 --client-id=client-id
...                 --client-secret=client-secret
...                 --port=${APIPORT}
...                 --proto=http
...                 --include-gateway-name=LOCATION_501
...                 --timeout=10


*** Test Cases ***
Gateway-containers ${tc}
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
    ...    OK: gateway 'LOCATION_501' all containers are ok | 'gateways.detected.count'=1;;;0; 'LOCATION_501~container1#gateway.cpu.utilization.percentage'=4.20%;;;0;100 'LOCATION_501~container1#gateway.memory.usage.bytes'=168191590B;;;0; 'LOCATION_501~container2#gateway.cpu.utilization.percentage'=0.02%;;;0;100 'LOCATION_501~container2#gateway.memory.usage.bytes'=3908042B;;;0; 'LOCATION_501~container3#gateway.cpu.utilization.percentage'=0.34%;;;0;100 'LOCATION_501~container3#gateway.memory.usage.bytes'=14963179B;;;0; 'LOCATION_501~container4#gateway.cpu.utilization.percentage'=0.58%;;;0;100 'LOCATION_501~container4#gateway.memory.usage.bytes'=89076531B;;;0; 'LOCATION_501~container5#gateway.cpu.utilization.percentage'=0.41%;;;0;100 'LOCATION_501~container5#gateway.memory.usage.bytes'=121425100B;;;0; 'LOCATION_501~container6#gateway.cpu.utilization.percentage'=6.35%;;;0;100 'LOCATION_501~container6#gateway.memory.usage.bytes'=171966464B;;;0; 'LOCATION_501~container7#gateway.cpu.utilization.percentage'=83.68%;;;0;100 'LOCATION_501~container7#gateway.memory.usage.bytes'=1550483193B;;;0;
    ...    2
    ...    --include-container-name=1
    ...    OK: gateway 'LOCATION_501' container 'container1' CPU usage: 4.20 %, memory used: 160.40 MB | 'gateways.detected.count'=1;;;0; 'LOCATION_501~container1#gateway.cpu.utilization.percentage'=4.20%;;;0;100 'LOCATION_501~container1#gateway.memory.usage.bytes'=168191590B;;;0;
    ...    3
    ...    --exclude-container-name=1
    ...    OK: gateway 'LOCATION_501' all containers are ok | 'gateways.detected.count'=1;;;0; 'LOCATION_501~container2#gateway.cpu.utilization.percentage'=0.02%;;;0;100 'LOCATION_501~container2#gateway.memory.usage.bytes'=3908042B;;;0; 'LOCATION_501~container3#gateway.cpu.utilization.percentage'=0.34%;;;0;100 'LOCATION_501~container3#gateway.memory.usage.bytes'=14963179B;;;0; 'LOCATION_501~container4#gateway.cpu.utilization.percentage'=0.58%;;;0;100 'LOCATION_501~container4#gateway.memory.usage.bytes'=89076531B;;;0; 'LOCATION_501~container5#gateway.cpu.utilization.percentage'=0.41%;;;0;100 'LOCATION_501~container5#gateway.memory.usage.bytes'=121425100B;;;0; 'LOCATION_501~container6#gateway.cpu.utilization.percentage'=6.35%;;;0;100 'LOCATION_501~container6#gateway.memory.usage.bytes'=171966464B;;;0; 'LOCATION_501~container7#gateway.cpu.utilization.percentage'=83.68%;;;0;100 'LOCATION_501~container7#gateway.memory.usage.bytes'=1550483193B;;;0;
    ...    4
    ...    --include-site-name=1
    ...    UNKNOWN: Number of gateways detected: 0 | 'gateways.detected.count'=0;;;0;
    ...    5
    ...    --exclude-site-name=5
    ...    UNKNOWN: Number of gateways detected: 0 | 'gateways.detected.count'=0;;;0;
    ...    6
    ...    --include-cluster-name=1
    ...    UNKNOWN: Number of gateways detected: 0 | 'gateways.detected.count'=0;;;0;
    ...    7
    ...    --exclude-cluster-name=1
    ...    OK: gateway 'LOCATION_501' all containers are ok | 'gateways.detected.count'=1;;;0; 'LOCATION_501~container1#gateway.cpu.utilization.percentage'=4.20%;;;0;100 'LOCATION_501~container1#gateway.memory.usage.bytes'=168191590B;;;0; 'LOCATION_501~container2#gateway.cpu.utilization.percentage'=0.02%;;;0;100 'LOCATION_501~container2#gateway.memory.usage.bytes'=3908042B;;;0; 'LOCATION_501~container3#gateway.cpu.utilization.percentage'=0.34%;;;0;100 'LOCATION_501~container3#gateway.memory.usage.bytes'=14963179B;;;0; 'LOCATION_501~container4#gateway.cpu.utilization.percentage'=0.58%;;;0;100 'LOCATION_501~container4#gateway.memory.usage.bytes'=89076531B;;;0; 'LOCATION_501~container5#gateway.cpu.utilization.percentage'=0.41%;;;0;100 'LOCATION_501~container5#gateway.memory.usage.bytes'=121425100B;;;0; 'LOCATION_501~container6#gateway.cpu.utilization.percentage'=6.35%;;;0;100 'LOCATION_501~container6#gateway.memory.usage.bytes'=171966464B;;;0; 'LOCATION_501~container7#gateway.cpu.utilization.percentage'=83.68%;;;0;100 'LOCATION_501~container7#gateway.memory.usage.bytes'=1550483193B;;;0;
    ...    8
    ...    --include-gateway-name=LOCATION_501
    ...    OK: gateway 'LOCATION_501' all containers are ok | 'gateways.detected.count'=1;;;0; 'LOCATION_501~container1#gateway.cpu.utilization.percentage'=4.20%;;;0;100 'LOCATION_501~container1#gateway.memory.usage.bytes'=168191590B;;;0; 'LOCATION_501~container2#gateway.cpu.utilization.percentage'=0.02%;;;0;100 'LOCATION_501~container2#gateway.memory.usage.bytes'=3908042B;;;0; 'LOCATION_501~container3#gateway.cpu.utilization.percentage'=0.34%;;;0;100 'LOCATION_501~container3#gateway.memory.usage.bytes'=14963179B;;;0; 'LOCATION_501~container4#gateway.cpu.utilization.percentage'=0.58%;;;0;100 'LOCATION_501~container4#gateway.memory.usage.bytes'=89076531B;;;0; 'LOCATION_501~container5#gateway.cpu.utilization.percentage'=0.41%;;;0;100 'LOCATION_501~container5#gateway.memory.usage.bytes'=121425100B;;;0; 'LOCATION_501~container6#gateway.cpu.utilization.percentage'=6.35%;;;0;100 'LOCATION_501~container6#gateway.memory.usage.bytes'=171966464B;;;0; 'LOCATION_501~container7#gateway.cpu.utilization.percentage'=83.68%;;;0;100 'LOCATION_501~container7#gateway.memory.usage.bytes'=1550483193B;;;0;
    ...    9
    ...    --exclude-gateway-name=1
    ...    UNKNOWN: Number of gateways detected: 0 | 'gateways.detected.count'=0;;;0;
    ...    10
    ...    --include-gateway-id=1
    ...    UNKNOWN: Number of gateways detected: 0 | 'gateways.detected.count'=0;;;0;
    ...    11
    ...    --exclude-gateway-id=1
    ...    OK: gateway 'LOCATION_501' all containers are ok | 'gateways.detected.count'=1;;;0; 'LOCATION_501~container1#gateway.cpu.utilization.percentage'=4.20%;;;0;100 'LOCATION_501~container1#gateway.memory.usage.bytes'=168191590B;;;0; 'LOCATION_501~container2#gateway.cpu.utilization.percentage'=0.02%;;;0;100 'LOCATION_501~container2#gateway.memory.usage.bytes'=3908042B;;;0; 'LOCATION_501~container3#gateway.cpu.utilization.percentage'=0.34%;;;0;100 'LOCATION_501~container3#gateway.memory.usage.bytes'=14963179B;;;0; 'LOCATION_501~container4#gateway.cpu.utilization.percentage'=0.58%;;;0;100 'LOCATION_501~container4#gateway.memory.usage.bytes'=89076531B;;;0; 'LOCATION_501~container5#gateway.cpu.utilization.percentage'=0.41%;;;0;100 'LOCATION_501~container5#gateway.memory.usage.bytes'=121425100B;;;0; 'LOCATION_501~container6#gateway.cpu.utilization.percentage'=6.35%;;;0;100 'LOCATION_501~container6#gateway.memory.usage.bytes'=171966464B;;;0; 'LOCATION_501~container7#gateway.cpu.utilization.percentage'=83.68%;;;0;100 'LOCATION_501~container7#gateway.memory.usage.bytes'=1550483193B;;;0;
    ...    12
    ...    --custom-perfdata-instances='%(gatewayName) %(containerName) %(gatewayName)'
    ...    OK: gateway 'LOCATION_501' all containers are ok | 'gateways.detected.count'=1;;;0; 'LOCATION_501~container1~LOCATION_501#gateway.cpu.utilization.percentage'=4.20%;;;0;100 'LOCATION_501~container1~LOCATION_501#gateway.memory.usage.bytes'=168191590B;;;0; 'LOCATION_501~container2~LOCATION_501#gateway.cpu.utilization.percentage'=0.02%;;;0;100 'LOCATION_501~container2~LOCATION_501#gateway.memory.usage.bytes'=3908042B;;;0; 'LOCATION_501~container3~LOCATION_501#gateway.cpu.utilization.percentage'=0.34%;;;0;100 'LOCATION_501~container3~LOCATION_501#gateway.memory.usage.bytes'=14963179B;;;0; 'LOCATION_501~container4~LOCATION_501#gateway.cpu.utilization.percentage'=0.58%;;;0;100 'LOCATION_501~container4~LOCATION_501#gateway.memory.usage.bytes'=89076531B;;;0; 'LOCATION_501~container5~LOCATION_501#gateway.cpu.utilization.percentage'=0.41%;;;0;100 'LOCATION_501~container5~LOCATION_501#gateway.memory.usage.bytes'=121425100B;;;0; 'LOCATION_501~container6~LOCATION_501#gateway.cpu.utilization.percentage'=6.35%;;;0;100 'LOCATION_501~container6~LOCATION_501#gateway.memory.usage.bytes'=171966464B;;;0; 'LOCATION_501~container7~LOCATION_501#gateway.cpu.utilization.percentage'=83.68%;;;0;100 'LOCATION_501~container7~LOCATION_501#gateway.memory.usage.bytes'=1550483193B;;;0;
    ...    13
    ...    --warning-gateways-detected=2:
    ...    WARNING: Number of gateways detected: 1 | 'gateways.detected.count'=1;2:;;0; 'LOCATION_501~container1#gateway.cpu.utilization.percentage'=4.20%;;;0;100 'LOCATION_501~container1#gateway.memory.usage.bytes'=168191590B;;;0; 'LOCATION_501~container2#gateway.cpu.utilization.percentage'=0.02%;;;0;100 'LOCATION_501~container2#gateway.memory.usage.bytes'=3908042B;;;0; 'LOCATION_501~container3#gateway.cpu.utilization.percentage'=0.34%;;;0;100 'LOCATION_501~container3#gateway.memory.usage.bytes'=14963179B;;;0; 'LOCATION_501~container4#gateway.cpu.utilization.percentage'=0.58%;;;0;100 'LOCATION_501~container4#gateway.memory.usage.bytes'=89076531B;;;0; 'LOCATION_501~container5#gateway.cpu.utilization.percentage'=0.41%;;;0;100 'LOCATION_501~container5#gateway.memory.usage.bytes'=121425100B;;;0; 'LOCATION_501~container6#gateway.cpu.utilization.percentage'=6.35%;;;0;100 'LOCATION_501~container6#gateway.memory.usage.bytes'=171966464B;;;0; 'LOCATION_501~container7#gateway.cpu.utilization.percentage'=83.68%;;;0;100 'LOCATION_501~container7#gateway.memory.usage.bytes'=1550483193B;;;0;
    ...    14
    ...    --critical-gateways-detected=2:
    ...    CRITICAL: Number of gateways detected: 1 | 'gateways.detected.count'=1;;2:;0; 'LOCATION_501~container1#gateway.cpu.utilization.percentage'=4.20%;;;0;100 'LOCATION_501~container1#gateway.memory.usage.bytes'=168191590B;;;0; 'LOCATION_501~container2#gateway.cpu.utilization.percentage'=0.02%;;;0;100 'LOCATION_501~container2#gateway.memory.usage.bytes'=3908042B;;;0; 'LOCATION_501~container3#gateway.cpu.utilization.percentage'=0.34%;;;0;100 'LOCATION_501~container3#gateway.memory.usage.bytes'=14963179B;;;0; 'LOCATION_501~container4#gateway.cpu.utilization.percentage'=0.58%;;;0;100 'LOCATION_501~container4#gateway.memory.usage.bytes'=89076531B;;;0; 'LOCATION_501~container5#gateway.cpu.utilization.percentage'=0.41%;;;0;100 'LOCATION_501~container5#gateway.memory.usage.bytes'=121425100B;;;0; 'LOCATION_501~container6#gateway.cpu.utilization.percentage'=6.35%;;;0;100 'LOCATION_501~container6#gateway.memory.usage.bytes'=171966464B;;;0; 'LOCATION_501~container7#gateway.cpu.utilization.percentage'=83.68%;;;0;100 'LOCATION_501~container7#gateway.memory.usage.bytes'=1550483193B;;;0;
    ...    15
    ...    --warning-memory-usage=1
    ...    WARNING: gateway 'LOCATION_501' container 'container1' memory used: 160.40 MB - container 'container2' memory used: 3.73 MB - container 'container3' memory used: 14.27 MB - container 'container4' memory used: 84.95 MB - container 'container5' memory used: 115.80 MB - container 'container6' memory used: 164.00 MB - container 'container7' memory used: 1.44 GB | 'gateways.detected.count'=1;;;0; 'LOCATION_501~container1#gateway.cpu.utilization.percentage'=4.20%;;;0;100 'LOCATION_501~container1#gateway.memory.usage.bytes'=168191590B;0:1;;0; 'LOCATION_501~container2#gateway.cpu.utilization.percentage'=0.02%;;;0;100 'LOCATION_501~container2#gateway.memory.usage.bytes'=3908042B;0:1;;0; 'LOCATION_501~container3#gateway.cpu.utilization.percentage'=0.34%;;;0;100 'LOCATION_501~container3#gateway.memory.usage.bytes'=14963179B;0:1;;0; 'LOCATION_501~container4#gateway.cpu.utilization.percentage'=0.58%;;;0;100 'LOCATION_501~container4#gateway.memory.usage.bytes'=89076531B;0:1;;0; 'LOCATION_501~container5#gateway.cpu.utilization.percentage'=0.41%;;;0;100 'LOCATION_501~container5#gateway.memory.usage.bytes'=121425100B;0:1;;0; 'LOCATION_501~container6#gateway.cpu.utilization.percentage'=6.35%;;;0;100 'LOCATION_501~container6#gateway.memory.usage.bytes'=171966464B;0:1;;0; 'LOCATION_501~container7#gateway.cpu.utilization.percentage'=83.68%;;;0;100 'LOCATION_501~container7#gateway.memory.usage.bytes'=1550483193B;0:1;;0;
    ...    16
    ...    --critical-memory-usage=1
    ...    CRITICAL: gateway 'LOCATION_501' container 'container1' memory used: 160.40 MB - container 'container2' memory used: 3.73 MB - container 'container3' memory used: 14.27 MB - container 'container4' memory used: 84.95 MB - container 'container5' memory used: 115.80 MB - container 'container6' memory used: 164.00 MB - container 'container7' memory used: 1.44 GB | 'gateways.detected.count'=1;;;0; 'LOCATION_501~container1#gateway.cpu.utilization.percentage'=4.20%;;;0;100 'LOCATION_501~container1#gateway.memory.usage.bytes'=168191590B;;0:1;0; 'LOCATION_501~container2#gateway.cpu.utilization.percentage'=0.02%;;;0;100 'LOCATION_501~container2#gateway.memory.usage.bytes'=3908042B;;0:1;0; 'LOCATION_501~container3#gateway.cpu.utilization.percentage'=0.34%;;;0;100 'LOCATION_501~container3#gateway.memory.usage.bytes'=14963179B;;0:1;0; 'LOCATION_501~container4#gateway.cpu.utilization.percentage'=0.58%;;;0;100 'LOCATION_501~container4#gateway.memory.usage.bytes'=89076531B;;0:1;0; 'LOCATION_501~container5#gateway.cpu.utilization.percentage'=0.41%;;;0;100 'LOCATION_501~container5#gateway.memory.usage.bytes'=121425100B;;0:1;0; 'LOCATION_501~container6#gateway.cpu.utilization.percentage'=6.35%;;;0;100 'LOCATION_501~container6#gateway.memory.usage.bytes'=171966464B;;0:1;0; 'LOCATION_501~container7#gateway.cpu.utilization.percentage'=83.68%;;;0;100 'LOCATION_501~container7#gateway.memory.usage.bytes'=1550483193B;;0:1;0;
    ...    17
    ...    --warning-cpu-utilization=1
    ...    WARNING: gateway 'LOCATION_501' container 'container1' CPU usage: 4.20 % - container 'container6' CPU usage: 6.35 % - container 'container7' CPU usage: 83.68 % | 'gateways.detected.count'=1;;;0; 'LOCATION_501~container1#gateway.cpu.utilization.percentage'=4.20%;0:1;;0;100 'LOCATION_501~container1#gateway.memory.usage.bytes'=168191590B;;;0; 'LOCATION_501~container2#gateway.cpu.utilization.percentage'=0.02%;0:1;;0;100 'LOCATION_501~container2#gateway.memory.usage.bytes'=3908042B;;;0; 'LOCATION_501~container3#gateway.cpu.utilization.percentage'=0.34%;0:1;;0;100 'LOCATION_501~container3#gateway.memory.usage.bytes'=14963179B;;;0; 'LOCATION_501~container4#gateway.cpu.utilization.percentage'=0.58%;0:1;;0;100 'LOCATION_501~container4#gateway.memory.usage.bytes'=89076531B;;;0; 'LOCATION_501~container5#gateway.cpu.utilization.percentage'=0.41%;0:1;;0;100 'LOCATION_501~container5#gateway.memory.usage.bytes'=121425100B;;;0; 'LOCATION_501~container6#gateway.cpu.utilization.percentage'=6.35%;0:1;;0;100 'LOCATION_501~container6#gateway.memory.usage.bytes'=171966464B;;;0; 'LOCATION_501~container7#gateway.cpu.utilization.percentage'=83.68%;0:1;;0;100 'LOCATION_501~container7#gateway.memory.usage.bytes'=1550483193B;;;0;
    ...    18
    ...    --critical-cpu-utilization=1
    ...    CRITICAL: gateway 'LOCATION_501' container 'container1' CPU usage: 4.20 % - container 'container6' CPU usage: 6.35 % - container 'container7' CPU usage: 83.68 % | 'gateways.detected.count'=1;;;0; 'LOCATION_501~container1#gateway.cpu.utilization.percentage'=4.20%;;0:1;0;100 'LOCATION_501~container1#gateway.memory.usage.bytes'=168191590B;;;0; 'LOCATION_501~container2#gateway.cpu.utilization.percentage'=0.02%;;0:1;0;100 'LOCATION_501~container2#gateway.memory.usage.bytes'=3908042B;;;0; 'LOCATION_501~container3#gateway.cpu.utilization.percentage'=0.34%;;0:1;0;100 'LOCATION_501~container3#gateway.memory.usage.bytes'=14963179B;;;0; 'LOCATION_501~container4#gateway.cpu.utilization.percentage'=0.58%;;0:1;0;100 'LOCATION_501~container4#gateway.memory.usage.bytes'=89076531B;;;0; 'LOCATION_501~container5#gateway.cpu.utilization.percentage'=0.41%;;0:1;0;100 'LOCATION_501~container5#gateway.memory.usage.bytes'=121425100B;;;0; 'LOCATION_501~container6#gateway.cpu.utilization.percentage'=6.35%;;0:1;0;100 'LOCATION_501~container6#gateway.memory.usage.bytes'=171966464B;;;0; 'LOCATION_501~container7#gateway.cpu.utilization.percentage'=83.68%;;0:1;0;100 'LOCATION_501~container7#gateway.memory.usage.bytes'=1550483193B;;;0;
