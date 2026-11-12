*** Settings ***
Documentation       Prometheus cAdvisor exporter - CPU mode

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}metrics.mockoon.json

${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=cloud::prometheus::exporters::cadvisor::plugin
...                 --mode=cpu
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --url-path=/api/v1


*** Test Cases ***
CPU ${tc}
    [Tags]    cloud    prometheus    cadvisor

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
    ...    --verbose
    ...    OK: All containers CPU usage are ok | 'usage_web-1_nginx'=14.00%;;;0;100 'throttled_web-1_nginx'=2.50%;;;0;100 'usage_multi_app'=22.00%;;;0;100 'usage_multi_sidecar'=6.00%;;;0;100\nContainer 'nginx' [pod: web-1] CPU Usage: 14.00 %, Throttled: 2.50 %\nContainer 'app' [pod: multi] CPU Usage: 22.00 %\nContainer 'sidecar' [pod: multi] CPU Usage: 6.00 %
    ...    2
    ...    --container='container=""'
    ...    OK: All containers CPU usage are ok | 'usage_web-1'=15.00%;;;0;100 'usage_multi'=30.00%;;;0;100
    ...    3
    ...    --container='name="haproxy"'
    ...    OK: Container 'haproxy' CPU Usage: 5.00 % | 'usage'=5.00%;;;0;100
    ...    4
    ...    --pod='pod="web-1"' --verbose
    ...    OK: All containers CPU usage are ok | 'usage_web-1_nginx'=14.00%;;;0;100 'throttled_web-1_nginx'=2.50%;;;0;100 'usage_web-1_nginx'=42.00%;;;0;100 'throttled_web-1_nginx'=0.00%;;;0;100\nContainer 'nginx' [pod: web-1] CPU Usage: 14.00 %, Throttled: 2.50 %\nContainer 'nginx' [pod: web-1] CPU Usage: 42.00 %, Throttled: 0.00 %
    ...    5
    ...    --warning-usage=20 --critical-usage=25
    ...    WARNING: Container 'app' [pod: multi] CPU Usage: 22.00 % | 'usage_web-1_nginx'=14.00%;0:20;0:25;0;100 'throttled_web-1_nginx'=2.50%;;;0;100 'usage_multi_app'=22.00%;0:20;0:25;0;100 'usage_multi_sidecar'=6.00%;0:20;0:25;0;100
    ...    6
    ...    --critical-throttled=2
    ...    CRITICAL: Container 'nginx' [pod: web-1] CPU Throttled: 2.50 % | 'usage_web-1_nginx'=14.00%;;;0;100 'throttled_web-1_nginx'=2.50%;;0:2;0;100 'usage_multi_app'=22.00%;;;0;100 'usage_multi_sidecar'=6.00%;;;0;100
    ...    7
    ...    --container='container="absent"'
    ...    UNKNOWN: No containers found.
    ...    8
    ...    --pod='not a filter'
    ...    UNKNOWN: Need to specify --pod option as a PromQL filter.
