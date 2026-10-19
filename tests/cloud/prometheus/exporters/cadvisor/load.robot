*** Settings ***
Documentation       Prometheus cAdvisor exporter - load mode

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}metrics.mockoon.json

${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=cloud::prometheus::exporters::cadvisor::plugin
...                 --mode=load
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --url-path=/api/v1


*** Test Cases ***
Load ${tc}
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
    ...    OK: All containers load are ok | 'load_multi_app'=2.00;;;0; 'load_multi_sidecar'=0.00;;;0; 'load_web-1_nginx'=3.00;;;0;\nContainer 'app' [pod: multi] Load: 2.00\nContainer 'sidecar' [pod: multi] Load: 0.00\nContainer 'nginx' [pod: web-1] Load: 3.00
    ...    2
    ...    --container='container=""'
    ...    OK: All containers load are ok | 'load_multi'=1.00;;;0; 'load_web-1'=4.00;;;0;
    ...    3
    ...    --container='name="haproxy"'
    ...    OK: Container 'haproxy' Load: 7.00 | 'load'=7.00;;;0;
    ...    4
    ...    --warning-load=2.5
    ...    WARNING: Container 'nginx' [pod: web-1] Load: 3.00 | 'load_multi_app'=2.00;0:2.5;;0; 'load_multi_sidecar'=0.00;0:2.5;;0; 'load_web-1_nginx'=3.00;0:2.5;;0;
    ...    5
    ...    --critical-load=1.5
    ...    CRITICAL: Container 'app' [pod: multi] Load: 2.00 - Container 'nginx' [pod: web-1] Load: 3.00 | 'load_multi_app'=2.00;;0:1.5;0; 'load_multi_sidecar'=0.00;;0:1.5;0; 'load_web-1_nginx'=3.00;;0:1.5;0;
    ...    6
    ...    --container='container="absent"'
    ...    UNKNOWN: No containers found.
    ...    7
    ...    --pod='not a filter'
    ...    UNKNOWN: Need to specify --pod option as a PromQL filter.
