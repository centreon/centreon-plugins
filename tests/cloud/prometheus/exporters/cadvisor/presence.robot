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
    ...    OK: Resources detected: 8 - All resources are present | 'resources.detected.count'=8;;1:;0; '10.224.4.59:10250~haproxy#resource.last_seen.seconds'=0.71s;;;0; 'default~batch-crashloop#resource.last_seen.seconds'=0.71s;;;0; 'default~web-7d9f8b6c5-q8z7m~nginx#resource.last_seen.seconds'=0.71s;;;0; 'default~web-7d9f8b6c5-x2k4p~nginx#resource.last_seen.seconds'=0.71s;;;0; 'docker-b:8080~haproxy#resource.last_seen.seconds'=250.71s;;;0; 'monitoring~alertmanager-main-0#resource.last_seen.seconds'=0.71s;;;0; 'monitoring~alertmanager-main-0~alertmanager#resource.last_seen.seconds'=4.71s;;;0; 'monitoring~alertmanager-main-0~config-reloader#resource.last_seen.seconds'=300.71s;;;0;
    ...    2
    ...    --verbose
    ...    OK: Resources detected: 8 - All resources are present | 'resources.detected.count'=8;;1:;0; '10.224.4.59:10250~haproxy#resource.last_seen.seconds'=0.71s;;;0; 'default~batch-crashloop#resource.last_seen.seconds'=0.71s;;;0; 'default~web-7d9f8b6c5-q8z7m~nginx#resource.last_seen.seconds'=0.71s;;;0; 'default~web-7d9f8b6c5-x2k4p~nginx#resource.last_seen.seconds'=0.71s;;;0; 'docker-b:8080~haproxy#resource.last_seen.seconds'=250.71s;;;0; 'monitoring~alertmanager-main-0#resource.last_seen.seconds'=0.71s;;;0; 'monitoring~alertmanager-main-0~alertmanager#resource.last_seen.seconds'=4.71s;;;0; 'monitoring~alertmanager-main-0~config-reloader#resource.last_seen.seconds'=300.71s;;;0;\nContainer 'haproxy' [instance: 10.224.4.59:10250] last seen 0.71s ago\nPod 'batch-crashloop' [namespace: default] last seen 0.71s ago\nContainer 'nginx' [pod: web-7d9f8b6c5-q8z7m] [namespace: default] last seen 0.71s ago\nContainer 'nginx' [pod: web-7d9f8b6c5-x2k4p] [namespace: default] last seen 0.71s ago\nContainer 'haproxy' [instance: docker-b:8080] last seen 250.71s ago\nPod 'alertmanager-main-0' [namespace: monitoring] last seen 0.71s ago\nContainer 'alertmanager' [pod: alertmanager-main-0] [namespace: monitoring] last seen 4.71s ago\nContainer 'config-reloader' [pod: alertmanager-main-0] [namespace: monitoring] last seen 300.71s ago
    ...    3
    ...    --pod='pod="alertmanager-main-0"' --container='container=""'
    ...    OK: Resources detected: 1 - Pod 'alertmanager-main-0' [namespace: monitoring] last seen 0.71s ago | 'resources.detected.count'=1;;1:;0; 'monitoring~alertmanager-main-0#resource.last_seen.seconds'=0.71s;;;0;
    ...    4
    ...    --pod='pod="web-7d9f8b6c5-x2k4p"'
    ...    OK: Resources detected: 1 - Container 'nginx' [pod: web-7d9f8b6c5-x2k4p] [namespace: default] last seen 0.71s ago | 'resources.detected.count'=1;;1:;0; 'default~web-7d9f8b6c5-x2k4p~nginx#resource.last_seen.seconds'=0.71s;;;0;
    ...    5
    ...    --container='container="absent"'
    ...    CRITICAL: Resources detected: 0 | 'resources.detected.count'=0;;1:;0;
    ...    6
    ...    --container='name="haproxy"'
    ...    OK: Resources detected: 2 - All resources are present | 'resources.detected.count'=2;;1:;0; '10.224.4.59:10250~haproxy#resource.last_seen.seconds'=0.71s;;;0; 'docker-b:8080~haproxy#resource.last_seen.seconds'=250.71s;;;0;
    ...    7
    ...    --warning-last-seen=60 --critical-last-seen=500
    ...    WARNING: Container 'haproxy' [instance: docker-b:8080] last seen 250.71s ago - Container 'config-reloader' [pod: alertmanager-main-0] [namespace: monitoring] last seen 300.71s ago | 'resources.detected.count'=8;;1:;0; '10.224.4.59:10250~haproxy#resource.last_seen.seconds'=0.71s;0:60;0:500;0; 'default~batch-crashloop#resource.last_seen.seconds'=0.71s;0:60;0:500;0; 'default~web-7d9f8b6c5-q8z7m~nginx#resource.last_seen.seconds'=0.71s;0:60;0:500;0; 'default~web-7d9f8b6c5-x2k4p~nginx#resource.last_seen.seconds'=0.71s;0:60;0:500;0; 'docker-b:8080~haproxy#resource.last_seen.seconds'=250.71s;0:60;0:500;0; 'monitoring~alertmanager-main-0#resource.last_seen.seconds'=0.71s;0:60;0:500;0; 'monitoring~alertmanager-main-0~alertmanager#resource.last_seen.seconds'=4.71s;0:60;0:500;0; 'monitoring~alertmanager-main-0~config-reloader#resource.last_seen.seconds'=300.71s;0:60;0:500;0;
    ...    8
    ...    --critical-last-seen=60
    ...    CRITICAL: Container 'haproxy' [instance: docker-b:8080] last seen 250.71s ago - Container 'config-reloader' [pod: alertmanager-main-0] [namespace: monitoring] last seen 300.71s ago | 'resources.detected.count'=8;;1:;0; '10.224.4.59:10250~haproxy#resource.last_seen.seconds'=0.71s;;0:60;0; 'default~batch-crashloop#resource.last_seen.seconds'=0.71s;;0:60;0; 'default~web-7d9f8b6c5-q8z7m~nginx#resource.last_seen.seconds'=0.71s;;0:60;0; 'default~web-7d9f8b6c5-x2k4p~nginx#resource.last_seen.seconds'=0.71s;;0:60;0; 'docker-b:8080~haproxy#resource.last_seen.seconds'=250.71s;;0:60;0; 'monitoring~alertmanager-main-0#resource.last_seen.seconds'=0.71s;;0:60;0; 'monitoring~alertmanager-main-0~alertmanager#resource.last_seen.seconds'=4.71s;;0:60;0; 'monitoring~alertmanager-main-0~config-reloader#resource.last_seen.seconds'=300.71s;;0:60;0;
    ...    9
    ...    --critical-resources-detected=9:
    ...    CRITICAL: Resources detected: 8 | 'resources.detected.count'=8;;9:;0; '10.224.4.59:10250~haproxy#resource.last_seen.seconds'=0.71s;;;0; 'default~batch-crashloop#resource.last_seen.seconds'=0.71s;;;0; 'default~web-7d9f8b6c5-q8z7m~nginx#resource.last_seen.seconds'=0.71s;;;0; 'default~web-7d9f8b6c5-x2k4p~nginx#resource.last_seen.seconds'=0.71s;;;0; 'docker-b:8080~haproxy#resource.last_seen.seconds'=250.71s;;;0; 'monitoring~alertmanager-main-0#resource.last_seen.seconds'=0.71s;;;0; 'monitoring~alertmanager-main-0~alertmanager#resource.last_seen.seconds'=4.71s;;;0; 'monitoring~alertmanager-main-0~config-reloader#resource.last_seen.seconds'=300.71s;;;0;
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
    ...    OK: Resources detected: 7 - All resources are present | 'resources.detected.count'=7;;1:;0; '10.224.4.59:10250~haproxy#resource.last_seen.seconds'=0.71s;;;0; 'default~batch-crashloop#resource.last_seen.seconds'=0.71s;;;0; 'default~web-7d9f8b6c5-q8z7m~nginx#resource.last_seen.seconds'=0.71s;;;0; 'default~web-7d9f8b6c5-x2k4p~nginx#resource.last_seen.seconds'=0.71s;;;0; 'monitoring~alertmanager-main-0#resource.last_seen.seconds'=0.71s;;;0; 'monitoring~alertmanager-main-0~alertmanager#resource.last_seen.seconds'=4.71s;;;0; 'monitoring~alertmanager-main-0~config-reloader#resource.last_seen.seconds'=300.71s;;;0;
