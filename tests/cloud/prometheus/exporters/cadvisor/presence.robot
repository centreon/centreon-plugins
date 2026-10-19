*** Settings ***
Documentation       Prometheus cAdvisor exporter - presence mode

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json

${BASE_CMD}         ${CENTREON_PLUGINS}
...                 --plugin=cloud::prometheus::exporters::cadvisor::plugin
...                 --mode=presence
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
${CMD}              ${BASE_CMD} --url-path=/api/v1


*** Test Cases ***
Presence ${tc}
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
    ...    ${EMPTY}
    ...    OK: Containers detected: 7 - All containers are present | 'containers.detected.count'=7;;1:;0; 'alertmanager-main-0#container.last_seen.seconds'=0.71s;;;0; 'alertmanager-main-0~alertmanager#container.last_seen.seconds'=4.71s;;;0; 'alertmanager-main-0~config-reloader#container.last_seen.seconds'=300.71s;;;0; 'batch-crashloop#container.last_seen.seconds'=0.71s;;;0; 'haproxy#container.last_seen.seconds'=0.71s;;;0; 'web-7d9f8b6c5-q8z7m~nginx#container.last_seen.seconds'=0.71s;;;0; 'web-7d9f8b6c5-x2k4p~nginx#container.last_seen.seconds'=0.71s;;;0;
    ...    2
    ...    --verbose
    ...    OK: Containers detected: 7 - All containers are present | 'containers.detected.count'=7;;1:;0; 'alertmanager-main-0#container.last_seen.seconds'=0.71s;;;0; 'alertmanager-main-0~alertmanager#container.last_seen.seconds'=4.71s;;;0; 'alertmanager-main-0~config-reloader#container.last_seen.seconds'=300.71s;;;0; 'batch-crashloop#container.last_seen.seconds'=0.71s;;;0; 'haproxy#container.last_seen.seconds'=0.71s;;;0; 'web-7d9f8b6c5-q8z7m~nginx#container.last_seen.seconds'=0.71s;;;0; 'web-7d9f8b6c5-x2k4p~nginx#container.last_seen.seconds'=0.71s;;;0;\nPod 'alertmanager-main-0' last seen 0.71s ago\nContainer 'alertmanager' [pod: alertmanager-main-0] last seen 4.71s ago\nContainer 'config-reloader' [pod: alertmanager-main-0] last seen 300.71s ago\nPod 'batch-crashloop' last seen 0.71s ago\nContainer 'haproxy' last seen 0.71s ago\nContainer 'nginx' [pod: web-7d9f8b6c5-q8z7m] last seen 0.71s ago\nContainer 'nginx' [pod: web-7d9f8b6c5-x2k4p] last seen 0.71s ago
    ...    3
    ...    --pod='pod="alertmanager-main-0"' --container='container=""'
    ...    OK: Containers detected: 1 - Pod 'alertmanager-main-0' last seen 0.71s ago | 'containers.detected.count'=1;;1:;0; 'alertmanager-main-0#container.last_seen.seconds'=0.71s;;;0;
    ...    4
    ...    --pod='pod="web-7d9f8b6c5-x2k4p"'
    ...    OK: Containers detected: 1 - Container 'nginx' [pod: web-7d9f8b6c5-x2k4p] last seen 0.71s ago | 'containers.detected.count'=1;;1:;0; 'web-7d9f8b6c5-x2k4p~nginx#container.last_seen.seconds'=0.71s;;;0;
    ...    5
    ...    --container='container="absent"'
    ...    CRITICAL: Containers detected: 0 | 'containers.detected.count'=0;;1:;0;
    ...    6
    ...    --container='name="haproxy"'
    ...    OK: Containers detected: 1 - Container 'haproxy' last seen 0.71s ago | 'containers.detected.count'=1;;1:;0; 'haproxy#container.last_seen.seconds'=0.71s;;;0;
    ...    7
    ...    --warning-last-seen=60 --critical-last-seen=500
    ...    WARNING: Container 'config-reloader' [pod: alertmanager-main-0] last seen 300.71s ago | 'containers.detected.count'=7;;1:;0; 'alertmanager-main-0#container.last_seen.seconds'=0.71s;0:60;0:500;0; 'alertmanager-main-0~alertmanager#container.last_seen.seconds'=4.71s;0:60;0:500;0; 'alertmanager-main-0~config-reloader#container.last_seen.seconds'=300.71s;0:60;0:500;0; 'batch-crashloop#container.last_seen.seconds'=0.71s;0:60;0:500;0; 'haproxy#container.last_seen.seconds'=0.71s;0:60;0:500;0; 'web-7d9f8b6c5-q8z7m~nginx#container.last_seen.seconds'=0.71s;0:60;0:500;0; 'web-7d9f8b6c5-x2k4p~nginx#container.last_seen.seconds'=0.71s;0:60;0:500;0;
    ...    8
    ...    --critical-last-seen=60
    ...    CRITICAL: Container 'config-reloader' [pod: alertmanager-main-0] last seen 300.71s ago | 'containers.detected.count'=7;;1:;0; 'alertmanager-main-0#container.last_seen.seconds'=0.71s;;0:60;0; 'alertmanager-main-0~alertmanager#container.last_seen.seconds'=4.71s;;0:60;0; 'alertmanager-main-0~config-reloader#container.last_seen.seconds'=300.71s;;0:60;0; 'batch-crashloop#container.last_seen.seconds'=0.71s;;0:60;0; 'haproxy#container.last_seen.seconds'=0.71s;;0:60;0; 'web-7d9f8b6c5-q8z7m~nginx#container.last_seen.seconds'=0.71s;;0:60;0; 'web-7d9f8b6c5-x2k4p~nginx#container.last_seen.seconds'=0.71s;;0:60;0;
    ...    9
    ...    --critical-containers-detected=8:
    ...    CRITICAL: Containers detected: 7 | 'containers.detected.count'=7;;8:;0; 'alertmanager-main-0#container.last_seen.seconds'=0.71s;;;0; 'alertmanager-main-0~alertmanager#container.last_seen.seconds'=4.71s;;;0; 'alertmanager-main-0~config-reloader#container.last_seen.seconds'=300.71s;;;0; 'batch-crashloop#container.last_seen.seconds'=0.71s;;;0; 'haproxy#container.last_seen.seconds'=0.71s;;;0; 'web-7d9f8b6c5-q8z7m~nginx#container.last_seen.seconds'=0.71s;;;0; 'web-7d9f8b6c5-x2k4p~nginx#container.last_seen.seconds'=0.71s;;;0;
    ...    10
    ...    --container='pas un filtre'
    ...    UNKNOWN: Need to specify --container option as a PromQL filter.
    ...    11
    ...    --name-label='bad label'
    ...    UNKNOWN: Need to specify --name-label option as a Prometheus label name.

Presence legacy labels
    [Tags]    cloud    prometheus    cadvisor

    ${command}    Catenate
    ...    ${BASE_CMD}
    ...    --url-path=/legacy/api/v1
    ...    --container='container_name!~".*POD.*"' --pod='pod_name=~".*"'

    Ctn Run Command And Check Result As Strings
    ...    ${command}
    ...    OK: Containers detected: 7 - All containers are present | 'containers.detected.count'=7;;1:;0; 'alertmanager-main-0#container.last_seen.seconds'=0.71s;;;0; 'alertmanager-main-0~alertmanager#container.last_seen.seconds'=4.71s;;;0; 'alertmanager-main-0~config-reloader#container.last_seen.seconds'=300.71s;;;0; 'batch-crashloop#container.last_seen.seconds'=0.71s;;;0; 'haproxy#container.last_seen.seconds'=0.71s;;;0; 'web-7d9f8b6c5-q8z7m~nginx#container.last_seen.seconds'=0.71s;;;0; 'web-7d9f8b6c5-x2k4p~nginx#container.last_seen.seconds'=0.71s;;;0;
